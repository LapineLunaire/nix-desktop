# Base nix-darwin for Mac hosts: the shell, the system-wide tooling, and the nix daemon settings, on top of the platform-neutral option namespace and nix settings.
{
  config,
  lib,
  outputs,
  pkgs,
  ...
}: {
  imports = [
    outputs.modules.host
    outputs.modules.nix-settings
  ];

  programs.zsh.enable = true;

  # nix-darwin has no programs.nh module, so the package is installed here and NH_FLAKE exported the way the NixOS one does.
  environment = {
    systemPackages = [
      pkgs.nh
      # terminfo so SSH sessions from a Ghostty terminal render correctly. nixpkgs' ghostty is Linux-only; ghostty-bin carries the darwin build.
      pkgs.ghostty-bin.terminfo
      # System-wide neovim so root shells have an editor. nix-darwin has no programs.neovim module, so wrapNeovim adds the vi and vim aliases the NixOS one would.
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
      # Disable the press-and-hold accent menu so key repeat works in all apps.
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
      # Allows dragging a window from anywhere in it.
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
      # Hide desktop icons so files on ~/Desktop stay off the wallpaper.
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
