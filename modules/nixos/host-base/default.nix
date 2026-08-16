{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../host.nix
    ../../nix-settings.nix
    ./packages.nix
    ./persistence.nix
    ./security.nix
    ./services.nix
    ./tmp-dirs.nix
  ];

  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
    # zram compresses pages in RAM, so swapping is cheap and a high swappiness keeps anonymous pages compressed.
    kernel.sysctl."vm.swappiness" = 100;
  };

  # wheel escalates with doas; persist keeps the authentication for a period after a successful prompt.
  security.doas = {
    enable = true;
    extraRules = [
      {
        groups = ["wheel"];
        persist = true;
      }
    ];
  };
  # doas-sudo-shim installs one binary, named sudo, that calls doas. host-base/security.nix disables the real sudo.
  environment.systemPackages = [pkgs.doas-sudo-shim];

  security.polkit.enable = true;

  zramSwap = {
    enable = true;
    memoryPercent = 30;
    priority = 100;
  };

  time.timeZone = lib.mkDefault "UTC";

  i18n = {
    extraLocaleSettings = {
      LC_TIME = "C.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    earlySetup = true;
  };

  networking.nftables.enable = true;
}
