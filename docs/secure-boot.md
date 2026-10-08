# Secure Boot and TPM2 on Camellya

## Installer signing keys

Run as root in Bash from the installer's checkout at `/mnt/persist/nix-config`.

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

Return to [installation](install-camellya.md#5-install-and-reboot) or [recovery](recover-camellya.md#reinstall-from-the-installer). Keep Secure Boot enforcement disabled until the signing keys are enrolled.

## Installed system: Secure Boot, then TPM2

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
