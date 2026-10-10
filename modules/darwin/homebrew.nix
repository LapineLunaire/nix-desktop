{
  homebrew = {
    enable = true;
    enableZshIntegration = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Remove formulae and casks absent from the generated Brewfile on activation.
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
