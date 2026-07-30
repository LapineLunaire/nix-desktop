# carmilla, the account this config exists for, present on every host: the OS account, the home-manager wiring, and the personal home modules. The login password comes from the sops secret carmilla-password-hash, declared per host.
# home.stateVersion is declared per host alongside system.stateVersion: it records the nixpkgs release that host was installed from, which no flag in this module can stand in for.
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

  home-manager.users.carmilla = {
    lib,
    osConfig,
    pkgs,
    ...
  }: {
    imports = [
      ./packages.nix
      ./programs.nix
    ];

    home = {
      username = "carmilla";
      homeDirectory = osConfig.users.users.carmilla.home;
    };

    programs.home-manager.enable = true;

    # Activate new and changed systemd user services on `home-manager switch` without requiring a logout/login cycle.
    systemd.user.startServices = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "sd-switch";
  };
}
