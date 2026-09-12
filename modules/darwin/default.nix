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

  # nix-darwin needs nh and its flake path configured directly.
  environment = {
    systemPackages = [
      pkgs.nh
      pkgs.ghostty-bin.terminfo
      # Provide vi/vim aliases for root shells too.
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
    gc = {
      automatic = true;
      interval.Weekday = 7; # Sunday
      options = "--delete-older-than 30d";
    };
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      # Prefer key repeat to the accent menu.
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
      NSWindowShouldDragOnGesture = true;
    };

    loginwindow.GuestEnabled = false;

    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

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
      FXDefaultSearchScope = "SCcf"; # search the current folder
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
      HideDesktop = true;
      EnableTiledWindowMargins = false;
    };
  };

  networking.applicationFirewall = {
    enable = true;
    allowSigned = true;
    # Third-party signatures alone should not grant inbound network access.
    allowSignedApp = false;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
