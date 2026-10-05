# Installation and recovery

Replace `<repo>` with the repository URL. After installation, use the [README quick start](../README.md#quick-start) for routine switches.

## Camellya

Boot an x86_64 NixOS installer in UEFI mode with Secure Boot enforcement disabled. Run installer commands as root in Bash. The kernel targets Zen 5; on other hardware, review `hosts/camellya/default.nix`, `hardware-configuration.nix`, and `displays.nix`.

### 1. Create the disk layout

These commands erase the disk. Confirm `/dev/nvme0n1` with `lsblk` before continuing, and keep the LUKS passphrase for recovery. The 200G and 100G volume sizes are examples; adjust them and leave space for `/home`.

```sh
lsblk
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 1GiB 100%
mkfs.vfat -F32 /dev/nvme0n1p1

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

### 2. Mount

```sh
mount -t tmpfs -o size=2G,mode=755 none /mnt
mkdir -p /mnt/{boot,nix,persist,home}
mount -o umask=0077 /dev/nvme0n1p1 /mnt/boot
mount -o noatime /dev/camellya/nix /mnt/nix
mount -o noatime,nosuid,nodev /dev/camellya/persist /mnt/persist
mount -o noatime,nosuid,nodev /dev/camellya/home /mnt/home
```

### 3. Checkout and UUIDs

```sh
git clone <repo> /mnt/persist/nix-config
cd /mnt/persist/nix-config
blkid /dev/nvme0n1p1 /dev/nvme0n1p2 /dev/camellya/nix /dev/camellya/persist /dev/camellya/home
```

Replace all five `by-uuid` values in `hosts/camellya/hardware-configuration.nix`: EFI, LUKS, `/nix`, `/persist`, `/home`. Formatting creates new UUIDs. Preserve the tmpfs root, `neededForBoot`, mount options, and hardware settings.

### 4. SSH host key and secrets

Create `/mnt/persist/etc/ssh/` and restore `ssh_host_ed25519_key` and `ssh_host_ed25519_key.pub` there; the private key must be root-owned with mode `0600`. With the original key, existing secrets need no re-encryption.

If no backup exists, generate a key and obtain its age recipient:

```sh
mkdir -p /mnt/persist/etc/ssh
ssh-keygen -t ed25519 -N "" -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#ssh-to-age \
  -c ssh-to-age < /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
```

Update `camellya_host` in `.sops.yaml`. The host key is the only recipient, so a new key cannot decrypt the existing file. Recreate the file with the keys `carmilla-password-hash`, `samba-username`, `samba-password`, and `attic-pull-token`, taking the values from the password manager:

```sh
rm hosts/camellya/secrets.yaml
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#sops \
  -c sops hosts/camellya/secrets.yaml
```

User creation needs the password hash, so the file must be complete before installation. The installed `sops` alias is not available in the installer.

### 5. Secure Boot signing keys

Restore `/var/lib/sbctl` into `/mnt/persist/var/lib/sbctl`, or create new keys as shown next. Always bind-mount the persisted `/var/lib` into the target, because Lanzaboote needs `/var/lib/sbctl` during installation.

```sh
install -d -m 0700 /mnt/persist/var/lib/sbctl
mkdir -p /mnt/var/lib
mount --bind /mnt/persist/var/lib /mnt/var/lib
```

For new keys only, create them in the persisted directory. The temporary config sets [sbctl's `keydir` and `guid`](https://github.com/Foxboron/sbctl/blob/0.18/docs/sbctl.conf.5.txt):

```sh
cat > /tmp/sbctl-install.yaml <<'EOF'
keydir: /mnt/persist/var/lib/sbctl/keys
guid: /mnt/persist/var/lib/sbctl/GUID
EOF
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#sbctl \
  -c sbctl --config /tmp/sbctl-install.yaml create-keys
```

### 6. Install and reboot

```sh
nixos-install --no-root-passwd --flake /mnt/persist/nix-config#camellya
chown -R 1000:100 /mnt/persist/nix-config
cd /
umount -R /mnt
vgchange -an camellya
cryptsetup close cryptroot
reboot
```

The checkout belongs to `carmilla:users` (UID 1000, GID 100). Root password login is locked, and root cannot log in over SSH. Log in locally as `carmilla` using the password whose hash you stored in SOPS.

Installation signs the boot entries. Leave Secure Boot enforcement disabled until the signing keys are enrolled; use the LUKS passphrase for the first boot.

### 7. Secure Boot, then TPM2

For new signing keys, enter firmware Setup Mode, preserving `dbx`, then boot the installed system. Follow the [Lanzaboote firmware guide](https://nix-community.github.io/lanzaboote/getting-started/enable-secure-boot.html).

```sh
doas sbctl status
doas sbctl verify
doas sbctl enroll-keys --microsoft
```

`sbctl verify` lists Lanzaboote's `kernel-*.efi` files under `EFI/nixos` as unsigned, which is expected. Skip enrollment if restored keys are already enrolled. Enable enforcement in firmware, reboot, and confirm `bootctl status` reports Secure Boot as `enabled (user)` or `enabled (deployed)`.

Only then verify the recovery passphrase and enroll TPM2 with a PIN:

```sh
doas cryptsetup open --test-passphrase /dev/nvme0n1p2
doas systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes --wipe-slot=tpm2 /dev/nvme0n1p2
```

This replaces old TPM tokens while retaining password slots. Reboot and confirm the PIN prompt. Rebuilds do not enroll LUKS tokens. PCR 7 records the Secure Boot state and the certificates that authorized the boot images; it does not measure the kernel, initrd, or command line. Keep the PIN and recovery passphrase. See `man systemd-cryptenroll` on Camellya for the installed version's enrollment reference.

### Recovery

The NixOS installer is unsigned, so temporarily disable Secure Boot to boot it. After recovery, re-enable enforcement and verify it as in step 7.

- **TPM unlock failure:** use the LUKS passphrase. Once Secure Boot is verified again, repeat the TPM enrollment in step 7.
- **Installer access:** skip all formatting. Unlock and activate the existing volumes, then mount them as in [step 2](#2-mount):

  ```sh
  cryptsetup open /dev/nvme0n1p2 cryptroot
  vgchange -ay camellya
  ```

- **Reinstall:** reuse the mounted checkout and existing UUIDs, restore the SSH and signing keys if needed, bind-mount the persisted `/var/lib` as in step 5, then run step 6.
- **Backups:** keep secure copies of `/home`, the needed `/persist` data, the SSH host key, and `/var/lib/sbctl`. Persistence alone is not a backup. Keep secret values in the password manager.

## Silverwolf

Before the first switch, you need:

- Apple Silicon and macOS 26 or later for the declared [Homebrew `container` formula](https://formulae.brew.sh/formula/container).
- An existing `carmilla` account at `/Users/carmilla`.
- [Homebrew](https://brew.sh/) and [multi-user Nix](https://nix.dev/manual/nix/2.34/installation/installing-binary.html); complete shell setup and check `brew --version` and `nix --version` in a new terminal.
- A Mac App Store sign-in for `masApps`.
- App Management permission for the terminal (**System Settings > Privacy & Security > App Management**), so activation can replace existing applications.

Review `hosts/silverwolf/default.nix` first. Activation updates and upgrades Homebrew packages and removes undeclared formulae and casks. nix-darwin does not install Homebrew; if Homebrew is missing, activation reports an error and skips Homebrew packages without aborting.

```sh
mkdir -p ~/projects
git clone <repo> ~/projects/nix-config
cd ~/projects/nix-config
sudo nix --extra-experimental-features 'nix-command flakes' run --inputs-from . nix-darwin#darwin-rebuild \
  -- switch --flake .#silverwolf
```

The first switch uses this checkout's pinned nix-darwin because `nh` is not installed yet. Then create `~/Pictures/Screenshots`.

## YubiKey SSH and Git signing (both hosts)

Run `ssh-keygen -K` in a separate private directory for each YubiKey. Match the downloaded public key against `users/carmilla/ssh-keys.nix`, then move the selected key pair to:

```text
~/.ssh/id_ed25519_sk_rk_carmilla
~/.ssh/id_ed25519_sk_rk_carmilla.pub
```

Both declared keys embed the application `ssh:lapine`, so [OpenSSH saves them](https://github.com/openssh/openssh-portable/blob/V_10_5_P1/ssh-keygen.c#L3095-L3213) as `id_ed25519_sk_rk_lapine` and `.pub`, with `_<user-id>` appended for a non-default resident user ID. Renaming the files does not change the embedded application. Separate directories prevent the second download from overwriting the first key's files or stopping at the overwrite prompt.
