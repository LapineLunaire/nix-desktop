{
  virtualisation.waydroid.enable = true;

  # Wine/Proton synchronization support.
  boot.kernelModules = ["ntsync"];

  environment.sessionVariables = {
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_ENABLE_HDR = "1";
  };

  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.anime-games-launcher.enable = true;
  programs.honkers-railway-launcher.enable = true;
}
