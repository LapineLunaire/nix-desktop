# Base darwin system, the counterpart of modules/nixos/host-base: nix settings and garbage collection, the tools nix-darwin has no module for, and the macOS system defaults, firewall, and keyboard remapping.
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../host.nix
    ../nix-settings.nix
  ];

  programs.zsh.enable = true;

  # nix-darwin has no programs.nh module, so install the package and export NH_FLAKE the way the NixOS one does.
  environment = {
    systemPackages = [
      pkgs.nh
      # terminfo so SSH sessions from a Ghostty terminal render correctly. nixpkgs' ghostty is Linux-only, ghostty-bin carries the darwin build.
      pkgs.ghostty-bin.terminfo
      # System-wide neovim so root shells have an editor; the user's configured neovim comes from home-manager. nix-darwin has no programs.neovim module, so wrapNeovim adds the vi and vim aliases the NixOS one would.
      (pkgs.wrapNeovim pkgs.neovim-unwrapped {
        viAlias = true;
        vimAlias = true;
      })
    ];
    variables.NH_FLAKE = config.host.flakePath;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  time.timeZone = lib.mkDefault "UTC";

  nix = {
    package = pkgs.nix;
    gc = {
      automatic = true;
      interval.Weekday = 7; # Sunday
      options = "--delete-older-than 30d";
    };
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      # Disable press-and-hold accent menu so key repeat works in all apps.
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.springing.enabled" = true;
      AppleICUForce24HourTime = true;
      # Allow dragging windows by clicking anywhere on them (not just the title bar).
      NSWindowShouldDragOnGesture = true;
    };

    loginwindow.GuestEnabled = false;

    CustomUserPreferences = {
      NSGlobalDomain.AppleActionOnDoubleClick = "Minimize";
      "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      "com.apple.assistant.support"."Assistant Enabled" = false;
      "com.apple.finder" = {
        FXICloudDriveDesktop = false;
        FXICloudDriveDocuments = false;
      };
      "com.apple.SubmitDiagInfo".AutoSubmit = false;
    };

    dock = {
      autohide = true;
      mru-spaces = false;
      tilesize = 64;
      minimize-to-application = true;
      show-recents = false;
    };

    finder = {
      _FXSortFoldersFirst = true;
      FXDefaultSearchScope = "SCcf"; # search current folder by default
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv"; # list view
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    screencapture = {
      location = "~/Pictures/Screenshots";
      disable-shadow = true;
    };

    trackpad.Clicking = true;

    menuExtraClock = {
      Show24Hour = true;
      ShowDayOfWeek = true;
    };

    WindowManager = {
      # Hide desktop icons so files on ~/Desktop don't clutter the wallpaper.
      HideDesktop = true;
      EnableTiledWindowMargins = false;
    };
  };

  networking.applicationFirewall = {
    enable = true;
    allowSigned = true;
    allowSignedApp = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
