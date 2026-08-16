{...}: {
  services.dbus.implementation = "broker";
  services.fstrim.enable = true;
  services.fwupd.enable = true;

  # NTS (RFC 8915) authenticates NTP over TLS, so an on-path attacker cannot spoof time responses.
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
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
    };
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # sops-nix derives its age key from the persisted copy of the host key. Each host's sops.nix adds its own defaultSopsFile and secrets.
  sops.age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
}
