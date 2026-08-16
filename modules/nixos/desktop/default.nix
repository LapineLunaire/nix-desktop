{inputs, ...}: {
  imports = [
    inputs.aagl.nixosModules.default
    ./services.nix
  ];

  networking.networkmanager.enable = true;

  # Keep the HDA codec powered; entering and leaving power save causes an audible pop.
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0
  '';

  virtualisation.waydroid.enable = true;

  # ntsync provides the kernel-side NT synchronisation primitives Wine and Proton use for Win32 sync objects.
  boot.kernelModules = ["ntsync"];

  nix = {
    # SCHED_IDLE on the daemon is inherited by its build processes, so a build only gets CPU time no other task wants.
    daemonCPUSchedPolicy = "idle";

    # The aagl project's own binary cache, so its game launchers come prebuilt.
    settings = {
      extra-substituters = ["https://ezkea.cachix.org"];
      extra-trusted-public-keys = ["ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="];
    };
  };

  # The pipewire module takes realtime scheduling from security.rtkit.enable and leaves the setting to the configuration.
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
    # Stem darkening in FreeType's CFF and autofitter engines adds weight to thin strokes at small sizes.
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
}
