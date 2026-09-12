{inputs, ...}: {
  imports = [
    inputs.aagl.nixosModules.default
    ./fonts.nix
  ];

  networking.networkmanager.enable = true;

  # Avoid pops when the HDA codec enters power saving.
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0
  '';

  virtualisation.waydroid.enable = true;

  # Wine/Proton synchronization support.
  boot.kernelModules = ["ntsync"];

  # Keep Nix builds below interactive work in the CPU scheduler.
  nix.daemonCPUSchedPolicy = "idle";

  security.rtkit.enable = true;

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_ENABLE_HDR = "1";
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  services.pcscd.enable = true;

  services.kmscon = {
    enable = true;
    useXkbConfig = true;
    config.hwaccel = true;
    config.font-name = "JetBrainsMono Nerd Font";
  };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 2;
  };

  services.displayManager.plasma-login-manager.enable = true;

  services.desktopManager.plasma6.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Avoid pops when ALSA devices resume.
    wireplumber.extraConfig."99-disable-suspend" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {"node.name" = "~alsa_input.*";}
            {"node.name" = "~alsa_output.*";}
          ];
          actions.update-props."session.suspend-timeout-seconds" = 0;
        }
      ];
    };
  };
}
