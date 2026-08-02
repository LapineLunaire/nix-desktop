# Impermanence baseline for every host: machine identity, the SSH host key (which also derives the sops age key), and service state. Hosts add anything outside /var in their own persistence.nix.
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
