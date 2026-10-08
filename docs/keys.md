# SSH identity and secrets

## Host identity and secrets

Run these steps as root in Bash from the Camellya installer's checkout at `/mnt/persist/nix-config`.

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

Return to [Camellya installation](install-camellya.md#4-prepare-identity-and-signing-keys) or [recovery](recover-camellya.md#reinstall-from-the-installer).

On installed Camellya, the `sops` shell alias derives the age identity from the root-owned SSH host key through doas.

## YubiKey SSH and Git signing (both hosts)

Run `ssh-keygen -K` in a separate private directory for each YubiKey. Match the downloaded public key against `users/carmilla/ssh-keys.nix`, then move the selected key pair to:

```text
~/.ssh/id_ed25519_sk_rk_carmilla
~/.ssh/id_ed25519_sk_rk_carmilla.pub
```
