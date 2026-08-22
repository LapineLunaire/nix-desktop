# Steam, the game launchers, OBS, nix-ld, and the Plasma applications this host excludes.
{pkgs, ...}: {
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kate
    konsole
    kwin-x11
  ];

  programs.nix-ld.enable = true;

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.anime-games-launcher.enable = true;
  programs.honkers-railway-launcher.enable = true;
}
