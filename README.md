# nix-desktop

Carmilla's desktop config: the two machines worked on directly. The servers live in their own repo.

| Host | Platform | Role |
|------|----------|------|
| camellya | x86_64-linux | Desktop |
| silverwolf | aarch64-darwin | MacBook |

Both hosts build against nixos-unstable, with home-manager, nixvim, and plasma-manager tracking it. camellya uses impermanence with a tmpfs `/`, so state persists only through explicitly declared paths, and its secrets are sops-nix encrypted to its SSH ed25519 host key.

The checkout lives at `/persist/nix-config` on camellya and `~/projects/nix-config` on silverwolf. `host.flakePath` records it per host, which is what `nh` builds from and where Plasma reads the wallpapers.

## Structure

```
flake.nix       Inputs, the two system definitions, and the packages output
hosts/          Per-host hardware, secrets, persistence, and app choices
modules/        host.nix and nix-settings.nix are platform-neutral and imported from both sides
  nixos/host-base/  Boot, escalation, locale, firewall, hardening, persistence, temp dirs
  nixos/desktop/    NetworkManager, the Wayland session, fonts, Plasma, PipeWire
  nixos/secure-boot.nix  Lanzaboote, imported by hosts with enrolled keys
  darwin/           The darwin counterpart of host-base
users/carmilla/ The account, the home-manager modules, and the wallpapers
pkgs/           The tibia client, exposed through the additions overlay
overlays.nix    additions (pkgs/) and modifications (overridden nixpkgs packages)
```

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

- Ghostty on macOS: nixpkgs' ghostty is Linux-only, so home-manager installs `ghostty-bin` (the official macOS build, copied into `~/Applications`) and the darwin base module installs its terminfo
- nix-darwin has no `programs.neovim` or `programs.nh` module, so the darwin base module installs a `wrapNeovim` build with the vi/vim aliases and exports `NH_FLAKE` itself
- camellya's kernel is rebuilt with `X86_NATIVE_CPU`, which detects the CPU it compiles on, so that host must be built on itself
- Console and session keyboard layouts are Colemak with a plain US fallback, switched with `grp:win_space_toggle`
- Plasma wallpapers are read from the flake checkout rather than the store, so the images are not copied in on every rebuild
- The RODECaster Duo routing renders a PipeWire config from a sops template, since the device node names carry its serial number

## Bootstrapping camellya

Boot from a NixOS installer ISO, then:

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

TPM2 enrollment happens after first boot (step 6); the passphrase keyslot stays as fallback.

**3. Mount**

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount /dev/nvme0n1p1 /mnt/boot
mount -o noatime /dev/camellya/nix /mnt/nix
mount -o noatime /dev/camellya/persist /mnt/persist
mount -o noatime /dev/camellya/home /mnt/home
```

**4. Generate the SSH host key (required for sops)**

```sh
mkdir -p /mnt/persist/etc/ssh
ssh-keygen -t ed25519 -N "" -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
```

The age recipient in `.sops.yaml` is derived from that key. If it is a new key, get the recipient with `ssh-to-age < /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub`, replace `camellya_host` in `.sops.yaml`, and re-encrypt with `sops updatekeys hosts/camellya/secrets.yaml`.

**5. Clone the repo and install**

```sh
mkdir -p /mnt/persist/nix-config
git clone <repo> /mnt/persist/nix-config
nixos-install --flake /mnt/persist/nix-config#camellya
```

**6. First boot: enroll secure boot, then the TPM2**

```sh
sbctl create-keys
sbctl enroll-keys --microsoft
```

Enroll the TPM2 into the LUKS header only after secure boot is enrolled and verified (`bootctl status`), since the seal binds to PCR 7:

```sh
systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2
```

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
