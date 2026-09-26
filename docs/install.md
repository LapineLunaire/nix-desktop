# Installation

Replace `<repo>` with the repository URL before running either host's clone command.

## Camellya

Boot an x86_64 NixOS installer in UEFI mode and run these commands as root in Bash. This procedure creates a fresh installation on `/dev/nvme0n1`; confirm the target with `lsblk` because the formatting steps erase its contents. Keep the LUKS passphrase available through the first boots. The configured kernel targets Zen 5; review that target before installing on different hardware.

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

The volume sizes are examples, not sizes enforced by Nix. Adjust them to the disk and leave space for `/home`. TPM2 enrollment happens after Secure Boot verification (step 8); the passphrase keyslot stays as fallback.

**3. Mount**

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount -o umask=0077 /dev/nvme0n1p1 /mnt/boot
mount -o noatime /dev/camellya/nix /mnt/nix
mount -o noatime,nosuid,nodev /dev/camellya/persist /mnt/persist
mount -o noatime,nosuid,nodev /dev/camellya/home /mnt/home
```

**4. Clone the repo and update the hardware identifiers**

```sh
git clone <repo> /mnt/persist/nix-config
cd /mnt/persist/nix-config
blkid /dev/nvme0n1p1 /dev/nvme0n1p2 /dev/camellya/nix /dev/camellya/persist /dev/camellya/home
```

Replace the five `by-uuid` identifiers in `hosts/camellya/hardware-configuration.nix` with the values reported by `blkid`: the EFI filesystem, LUKS container, and three XFS filesystems. Preserve the tmpfs root, `neededForBoot`, mount options, and hardware settings. Formatting generates new UUIDs; do not retain the committed values without checking them.

**5. Prepare the SSH host key and secrets**

Restore the existing host key and its `.pub` file to `/mnt/persist/etc/ssh/` if a backup is available; the private key must be owned by root with mode `0600`. Otherwise generate a new key:

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

The declared secrets are `carmilla-password-hash`, `samba-username`, `samba-password`, and `attic-pull-token`. Carmilla's password hash is needed before user creation. The installed user's `sops` alias is not available in the installer.

**6. Prepare Secure Boot signing keys in persistent storage**

The installer needs signing keys before it writes the bootloader. Restore an existing `/var/lib/sbctl` backup into `/mnt/persist/var/lib/sbctl`, or generate a new set there:

```sh
install -d -m 0700 /mnt/persist/var/lib/sbctl
mkdir -p /mnt/var/lib
mount --bind /mnt/persist/var/lib /mnt/var/lib

cat > /tmp/sbctl-install.yaml <<'EOF'
keydir: /mnt/persist/var/lib/sbctl/keys
guid: /mnt/persist/var/lib/sbctl/GUID
EOF
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#sbctl -c sbctl --config /tmp/sbctl-install.yaml create-keys
```

Skip `create-keys` when restoring keys. The bind mount makes the same persisted keys available at the install target's `/var/lib/sbctl`, where Lanzaboote expects them. See [sbctl 0.18's configuration reference](https://github.com/Foxboron/sbctl/blob/0.18/docs/sbctl.conf.5.txt) for `keydir` and `guid`.

**7. Install**

```sh
nixos-install --no-root-passwd --flake /mnt/persist/nix-config#camellya
chown -R 1000:100 /mnt/persist/nix-config
```

Root password login stays locked, and Camellya disables root SSH login. The checkout belongs to `carmilla:users` (UID 1000, GID 100), so the user can edit it. Log in using Carmilla's password from the SOPS hash.

Leave the checkout and unmount the target before rebooting:

```sh
cd /
umount -R /mnt
vgchange -an camellya
cryptsetup close cryptroot
reboot
```

The installation signs the boot entries using the keys from step 6. Boot the installed system with Secure Boot enforcement disabled while the new keys are not yet enrolled. Use the LUKS passphrase for this boot.

**8. Enroll Secure Boot, verify it, then enroll TPM2 unlock**

For new keys, enter the firmware's Secure Boot Setup Mode, preserving the forbidden-signature database (`dbx`), then boot the installed system again. Firmware-specific steps are in the [Lanzaboote guide](https://nix-community.github.io/lanzaboote/getting-started/enable-secure-boot.html). Check the signed boot entries and enroll the keys:

```sh
doas sbctl status
doas sbctl verify
doas sbctl enroll-keys --microsoft
```

If restored signing keys are already enrolled, skip enrollment. Enable Secure Boot enforcement in firmware if needed and reboot. Confirm `bootctl status` reports Secure Boot enabled in user or deployed mode. Only then enroll TPM2 unlock with PCR 7 and a PIN. PCR 7 measures Secure Boot policy, not the identity of this specific OS; with Microsoft certificates enrolled, it is not sufficient by itself to restrict unattended unlocking to this installation. A PIN adds a user-held factor. See the [systemd enrollment reference](https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptenroll.html).

First verify that your recovery passphrase works with `doas cryptsetup open --test-passphrase /dev/nvme0n1p2`. Then replace any old TPM enrollment:

```sh
doas systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes --wipe-slot=tpm2 /dev/nvme0n1p2
```

The combined command adds the new token before removing older TPM tokens; password slots remain intact. Reboot and verify that TPM unlock requests the PIN. A Nix rebuild does not change existing LUKS tokens: this enrollment is a separate administrative step. Keep the passphrase keyslot for recovery. Back up the SSH host key and `/var/lib/sbctl` securely for future reinstalls.

## Silverwolf

Start with Apple Silicon macOS and an existing `carmilla` account with home directory `/Users/carmilla`. Install [Homebrew](https://brew.sh/) and [multi-user Nix](https://nix.dev/manual/nix/2.34/installation/installing-binary.html), complete their shell setup, and verify `brew --version` and `nix --version` in a new terminal. Sign in to the Mac App Store for the declared `masApps`.

nix-darwin manages Homebrew packages but does not install Homebrew itself. If Homebrew is missing, activation prints an error and skips the declared brews, casks, and Mac App Store apps without aborting.

```sh
mkdir -p ~/projects
git clone <repo> ~/projects/nix-config
cd ~/projects/nix-config
```

Review the Homebrew list before activation: cleanup removes undeclared formulae and casks. First activation, before `nh` exists, uses the nix-darwin input pinned by this checkout:

```sh
sudo nix --extra-experimental-features 'nix-command flakes' run --inputs-from . nix-darwin#darwin-rebuild \
  -- switch --flake .#silverwolf
```

## Manual post-install steps

Run `ssh-keygen -K` in a new private directory for each YubiKey to retrieve its resident SSH key handles. OpenSSH prompts before overwriting a key file; declining stops the remaining downloads.

Both keys in `users/carmilla/ssh-keys.nix` embed the application `ssh:lapine`. With the default all-zero resident user ID, OpenSSH writes `id_ed25519_sk_rk_lapine` and its `.pub` companion. Other resident user IDs add a suffix and cannot be determined from the public keys. See the pinned [OpenSSH implementation](https://github.com/openssh/openssh-portable/blob/V_10_5_P1/ssh-keygen.c#L3095-L3213) for filename handling.

Match the downloaded public key against `users/carmilla/ssh-keys.nix`, then move the selected pair to `~/.ssh/id_ed25519_sk_rk_carmilla` and `~/.ssh/id_ed25519_sk_rk_carmilla.pub`. SSH and Git signing use this filename; renaming leaves the embedded application unchanged. Keep the other YubiKey's files separately.

On macOS:

- Create `~/Pictures/Screenshots`.
- Grant App Management permission to the terminal emulator in System Settings > Privacy & Security > App Management.
