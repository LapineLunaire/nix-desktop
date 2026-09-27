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
    package = pkgs.obs-studio.override {cudaSupport = true;};
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };
}
