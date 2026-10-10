{pkgs, ...}: {
  imports = [
    ./fonts.nix
  ];

  networking.networkmanager.enable = true;

  # Avoid pops when the HDA codec enters power saving.
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0
  '';

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
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kate
    konsole
    kwin-x11
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.kde-pim.enable = false;

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };

  services.pcscd.enable = true;

  services.xserver.xkb = {
    layout = "us,us";
    variant = "colemak,";
    options = "grp:win_space_toggle";
  };

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
    enableNotifications = true;
  };

  services.smartd.notifications.systembus-notify.enable = true;

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
