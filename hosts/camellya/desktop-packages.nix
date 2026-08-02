# camellya's own desktop choices on top of modules/nixos/desktop: the plasma apps it drops, Steam and the game launchers, OBS, and nix-ld.
{pkgs, ...}: {
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kate
    konsole
  ];

  programs.nix-ld.enable = true;

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    package = pkgs.obs-studio.override {cudaSupport = true;};
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.anime-games-launcher.enable = true;
  programs.honkers-railway-launcher.enable = true;
  environment.systemPackages = [pkgs.protonplus];
}
