# The services every host runs: dbus, fstrim, fwupd, NTS-authenticated chrony, and sshd, plus the sops age key derived from the persisted host key.
{...}: {
  services.dbus.implementation = "broker";
  services.fstrim.enable = true;
  services.fwupd.enable = true;

  # NTS (RFC 8915): TLS-authenticated NTP, prevents on-path attackers from spoofing time responses.
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = ["time.cloudflare.com"];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    # sops-nix derives its age decryption key from this host key.
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # The persisted copy of the host key above, not the /etc path, which does not work under impermanence. Each host's sops.nix adds only its own defaultSopsFile and secrets.
  sops.age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
}
