{outputs, ...}: {
  imports = [outputs.darwinModules.base];

  nixpkgs.hostPlatform = "aarch64-darwin";
  # nix-darwin's own state version counter, unrelated to the nixpkgs release below it.
  system.stateVersion = 6;
  home-manager.users.carmilla.home.stateVersion = "26.11";

  networking = {
    hostName = "silverwolf";
    computerName = "Silver Wolf";
  };
  system.primaryUser = "carmilla";

  time.timeZone = "Europe/Amsterdam";

  host.flakePath = "/Users/carmilla/projects/nix-config";

  homebrew = {
    enable = true;
    enableZshIntegration = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Casks absent from this list are removed on activation, which keeps the install declarative.
      cleanup = "uninstall";
    };
    # Homebrew updates only on nix-darwin activation, not during regular brew commands.
    global.autoUpdate = false;
    brews = ["container"];
    casks = [
      "altserver"
      "discord"
      "appcleaner"
      "moonlight"
      "linearmouse"
      "obs"
      "playcover-community"
      "prismlauncher"
      "proton-drive"
      "soundsource"
      "steam"
      "tidal"
      "wootility"
    ];
    masApps = {
      "AdGuard Mini" = 1440147259;
      "Amphetamine" = 937984704;
      "Bitwarden" = 1352778147;
      "Monal" = 1637078500;
      "WireGuard" = 1451685025;
      "Xcode" = 497799835;
    };
  };
}
