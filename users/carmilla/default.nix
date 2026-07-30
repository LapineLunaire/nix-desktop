# carmilla, the account this config exists for, present on every host. The login password comes from the sops secret carmilla-password-hash, declared per host.
{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.carmilla =
    {
      home =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "/Users/carmilla"
        else "/home/carmilla";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = import ./ssh-keys.nix;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      isNormalUser = true;
      uid = 1000;
      description = "Carmilla";
      hashedPasswordFile = config.sops.secrets."carmilla-password-hash".path;
      extraGroups = ["wheel" "video" "audio" "input"];
    };
}
