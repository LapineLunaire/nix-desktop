{config, ...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      "carmilla-password-hash".neededForUsers = true;
      "samba-username" = {};
      "samba-password" = {};
      "rodecaster-duo-serial" = {};
    };

    templates."samba-credentials".content = ''
      username=${config.sops.placeholder."samba-username"}
      password=${config.sops.placeholder."samba-password"}
    '';
  };
}
