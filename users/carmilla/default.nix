# carmilla: the interactive account on every system, its OS side and its home-manager wiring. On NixOS the login password comes from the carmilla-password-hash sops secret, which each host declares.
# home.stateVersion is declared per host alongside system.stateVersion, since it records the nixpkgs release that host was installed from.
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

    # Activate new and changed systemd user services on switch, without a logout and login cycle.
    systemd.user.startServices = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "sd-switch";
  };
}
