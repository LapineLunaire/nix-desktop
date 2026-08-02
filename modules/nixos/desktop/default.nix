# Desktop baseline: NetworkManager, the Wayland and Proton session variables, the ssh agent and waydroid. A desktop's own app choices live on the host importing this.
{inputs, ...}: {
  imports = [
    inputs.aagl.nixosModules.default
    ./fonts.nix
    ./services.nix
  ];

  networking.networkmanager.enable = true;

  # Keep the HDA codec powered; entering and leaving power save causes an audible pop.
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0
  '';

  virtualisation.waydroid.enable = true;

  # ntsync: kernel-side NT synchronization primitives used by Wine/Proton to reduce syscall overhead for games that rely heavily on Win32 sync objects.
  boot.kernelModules = ["ntsync"];

  # Pull in the aagl binary cache so anime game launchers don't build from source.
  nix.settings = inputs.aagl.nixConfig;

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
    # Enable stem darkening in FreeType's CFF and autofitter engines. This adds slight weight to thin strokes at small sizes, improving readability.
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
}
