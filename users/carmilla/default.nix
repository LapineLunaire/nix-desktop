# home.stateVersion is declared per host alongside system.stateVersion, since it records the release that host was installed from.
{
  config,
  inputs,
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
      extraGroups = ["wheel" "networkmanager"];
    };

  home-manager.users.carmilla = {
    lib,
    osConfig,
    pkgs,
    ...
  }: {
    imports = [
      inputs.plasma-manager.homeModules.plasma-manager
      ./desktop.nix
      ./packages.nix
      ./plasma.nix
      ./programs.nix
    ];

    home = {
      username = "carmilla";
      homeDirectory = osConfig.users.users.carmilla.home;
    };

    programs.home-manager.enable = true;

    # sd-switch starts new and changed systemd user services during activation.
    systemd.user.startServices = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "sd-switch";
  };
}
