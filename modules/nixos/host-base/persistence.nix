# host-base/services.nix derives the sops age key from the SSH host key persisted here. Hosts add anything outside /var in their own persistence.nix.
{...}: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
