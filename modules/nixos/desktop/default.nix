# Desktop baseline: NetworkManager, the Wayland and Proton session variables, waydroid, and the font set. A desktop's own app choices live on the host importing this.
{
  inputs,
  pkgs,
  ...
}: {
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

  # ntsync: kernel-side NT synchronization primitives used by Wine/Proton to reduce syscall overhead for games that rely heavily on Win32 sync objects.
  boot.kernelModules = ["ntsync"];

  # Pull in the aagl binary cache so anime game launchers don't build from source.
  nix.settings = inputs.aagl.nixConfig;

  security.rtkit.enable = true;

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

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];

    fontconfig = {
      subpixel.rgba = "rgb";

      # The CJK entries pin Han characters to the Japanese faces; fontconfig falls back to the Korean ones on its own.
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font"
          "Noto Sans Mono CJK JP"
        ];
        sansSerif = [
          "Noto Sans"
          "Noto Sans CJK JP"
        ];
        serif = [
          "Noto Serif"
          "Noto Serif CJK JP"
        ];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
