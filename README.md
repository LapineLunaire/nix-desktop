# nix-desktop

Carmilla's desktop config: the two machines worked on directly. The servers live in their own repo.

| Host | Platform | Role |
|------|----------|------|
| camellya | x86_64-linux | Desktop |
| silverwolf | aarch64-darwin | MacBook |

Both hosts build against the `nixos-unstable-small` branch, with home-manager, nixvim, and plasma-manager tracking it. camellya uses impermanence with a tmpfs `/`, so state persists only through explicitly declared paths, and its secrets are sops-nix encrypted to its SSH ed25519 host key.

The checkout lives at `/persist/nix-config` on camellya and `~/projects/nix-config` on silverwolf. `host.flakePath` records it per host, which is what `nh` builds from and where Plasma reads the wallpapers.

## Structure

```
flake.nix       Inputs, the two system definitions, the module export surface, and the packages output
hosts/          Per-host hardware, secrets, persistence, and app choices
modules/        host.nix and nix-settings.nix are platform-neutral and imported from both sides
  nixos/host-base/  Boot, escalation, locale, firewall, persistence, temp dirs
  nixos/desktop/    NetworkManager, the Wayland session, fonts, Plasma, PipeWire
  nixos/security.nix     Kernel, network, and user-account hardening
  nixos/secure-boot.nix  Lanzaboote, using signing keys prepared before installation
  darwin/           The darwin counterpart of host-base
users/carmilla/ The account, the home-manager modules, and the wallpapers
pkgs/           The tibia client, exposed through the additions overlay
overlays.nix    additions (pkgs/) and modifications (overridden nixpkgs packages)
```

Internal modules use relative imports. The flake still exports `nixosModules` and `darwinModules` for external consumers; platform-neutral modules live directly under `modules/`.

## Usage

```sh
# camellya
nh os switch .

# silverwolf
nh darwin switch .
```

`nix develop` gives the tools for working on the repo, and direnv enters it from `.envrc` on its own. Its shell hook sets `core.hooksPath`, which is per clone and cannot be carried in the repo, so the tracked hooks apply from the first time the shell is entered.

Editing secrets needs the age key derived from camellya's host key; the `sops` shell alias on Linux does that derivation:

```sh
sops hosts/camellya/secrets.yaml
```

To build a single package with the overlays applied:

```sh
nix build .\#nixosConfigurations.camellya.pkgs.<package>
```

## Implementation notes

- Ghostty on macOS: nixpkgs' `ghostty` is Linux-only, so home-manager installs `ghostty-bin` (the official macOS build, copied into `~/Applications/Home Manager Apps`) and the darwin base module installs its terminfo
- nix-darwin has no `programs.neovim` or `programs.nh` module, so the darwin base module installs a `wrapNeovim` build with the vi/vim aliases and exports `NH_FLAKE` itself
- camellya's kernel uses explicit `znver5` compiler flags, so compatible build machines can build and cache it; setting `host.cpu.march = null` uses the stock package for the selected kernel series
- Only `obs-studio` is overridden with `cudaSupport`, which adds `autoAddDriverRunpath` to its build
- The kernel console uses Colemak. The XKB session and kmscon offer Colemak and plain US, switched with `grp:win_space_toggle`
- Plasma reads wallpapers from the flake checkout; the tracked images also exist in the flake's store snapshot
- The RODECaster Duo routing renders a PipeWire config from a sops template, since the device node names carry its serial number
- uutils is preferred on the Linux user's PATH and in the development shell; system packages retain their GNU dependencies, including commands uutils does not implement
- `packages` is filtered by `meta.platforms`, so `tibia` is offered on x86_64-linux alone

## Bootstrapping camellya

Boot the installer in UEFI mode and run these commands from a root shell. This procedure creates a fresh installation on `/dev/nvme0n1`; the formatting steps erase its contents. Keep the LUKS passphrase available through the first boots.

**1. Partition**

```sh
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 1GiB 100%

mkfs.vfat -F32 /dev/nvme0n1p1
```

**2. Create the LUKS2 container, the LVM volumes, and their filesystems**

```sh
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot

pvcreate /dev/mapper/cryptroot
vgcreate camellya /dev/mapper/cryptroot
lvcreate -L 200G -n nix camellya
lvcreate -L 100G -n persist camellya
lvcreate -l 100%FREE -n home camellya

mkfs.xfs /dev/camellya/nix
mkfs.xfs /dev/camellya/persist
mkfs.xfs /dev/camellya/home
```

TPM2 enrollment happens after Secure Boot verification (step 8); the passphrase keyslot stays as fallback.

**3. Mount**

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount /dev/nvme0n1p1 /mnt/boot
mount -o noatime /dev/camellya/nix /mnt/nix
mount -o noatime /dev/camellya/persist /mnt/persist
mount -o noatime /dev/camellya/home /mnt/home
```

**4. Clone the repo and update the hardware identifiers**

```sh
git clone <repo> /mnt/persist/nix-config
cd /mnt/persist/nix-config
blkid /dev/nvme0n1p1 /dev/nvme0n1p2 /dev/camellya/nix /dev/camellya/persist /dev/camellya/home
```

Replace the five `by-uuid` identifiers in `hosts/camellya/hardware-configuration.nix` with these newly generated values: the EFI filesystem, LUKS container, and three XFS filesystems. Preserve the tmpfs root, `neededForBoot`, mount options, and hardware settings. The committed UUIDs describe the existing installation and will not match freshly formatted filesystems.

**5. Prepare the SSH host key and secrets**

Restore the existing host key and its `.pub` file to `/mnt/persist/etc/ssh/` if a backup is available. Otherwise generate a new key:

```sh
mkdir -p /mnt/persist/etc/ssh
ssh-keygen -t ed25519 -N "" -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
```

For a new key, use the pinned tools to obtain its age recipient:

```sh
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#ssh-to-age \
  -c ssh-to-age < /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
```

Update `camellya_host` in `.sops.yaml`, then run the following with an existing authorized decryption identity available to SOPS:

```sh
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#sops \
  -c sops updatekeys hosts/camellya/secrets.yaml
```

A newly generated key cannot decrypt the existing ciphertext. If the old identity is unavailable, recreate the secret values and encrypt them for the new recipient before installing. Restoring the original host key does not require re-encryption.

**6. Prepare Secure Boot signing keys in persistent storage**

The installer needs signing keys before it writes the bootloader. Restore an existing `/var/lib/sbctl` backup into `/mnt/persist/var/lib/sbctl`, or generate a new set there:

```sh
mkdir -p /mnt/persist/var/lib/sbctl /mnt/var/lib
mount --bind /mnt/persist/var/lib /mnt/var/lib

cat > /tmp/sbctl-install.yaml <<'EOF'
keydir: /mnt/persist/var/lib/sbctl/keys
guid: /mnt/persist/var/lib/sbctl/GUID
EOF
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#sbctl -c sbctl --config /tmp/sbctl-install.yaml create-keys
```

Skip `create-keys` when restoring keys. The bind mount makes the same persisted keys available at the install target's `/var/lib/sbctl`, where Lanzaboote expects them. See [sbctl's configuration reference](https://github.com/Foxboron/sbctl/blob/master/docs/sbctl.conf.5.scd) for `keydir` and `guid`.

**7. Install**

```sh
nixos-install --flake /mnt/persist/nix-config#camellya
```

The installation signs the boot entries using the keys prepared above. Boot the installed system with Secure Boot enforcement disabled while the new keys are not yet enrolled. Use the LUKS passphrase for this boot.

**8. Enroll Secure Boot, verify it, then enroll TPM2 unlock**

For new keys, enter the firmware's Secure Boot Setup Mode, preserving the forbidden-signature database (`dbx`), then boot the installed system again. Firmware-specific steps are in the [Lanzaboote guide](https://nix-community.github.io/lanzaboote/getting-started/enable-secure-boot.html). Check the signed boot entries and enroll the keys:

```sh
doas sbctl status
doas sbctl verify
doas sbctl enroll-keys --microsoft
```

If restored signing keys are already enrolled, skip enrollment. Enable Secure Boot enforcement in firmware if needed and reboot. Confirm `bootctl status` reports Secure Boot enabled in user mode. Only then enroll TPM2 unlock with PCR 7 and a PIN. PCR 7 measures Secure Boot policy, not the identity of this specific OS; with Microsoft certificates enrolled, it is not sufficient by itself to restrict unattended unlocking to this installation. A PIN adds a user-held factor. See the [systemd enrollment reference](https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptenroll.html).

First verify that your recovery passphrase works with `doas cryptsetup open --test-passphrase /dev/nvme0n1p2`. Then replace any old TPM enrollment:

```sh
doas systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes --wipe-slot=tpm2 /dev/nvme0n1p2
```

The combined command adds the new token before removing older TPM tokens; password slots remain intact. Reboot and verify that TPM unlock requests the PIN. A Nix rebuild does not change existing LUKS tokens: this enrollment is a separate administrative step. Keep the passphrase keyslot for recovery. Back up the SSH host key and `/var/lib/sbctl` securely for future reinstalls.

## Bootstrapping silverwolf

nix-darwin manages Homebrew declaratively but cannot install it, so Homebrew comes first.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
git clone <repo> ~/projects/nix-config
```

First activation, before `nh` exists:

```sh
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/projects/nix-config#silverwolf
```

## Manual post-install steps

- Export the FIDO2 resident SSH keys from the YubiKey: `ssh-keygen -K` in `~/.ssh/`
- Create `~/Pictures/Screenshots` on macOS
- Grant App Management permission to the terminal emulator (System Settings > Privacy & Security > App Management)
