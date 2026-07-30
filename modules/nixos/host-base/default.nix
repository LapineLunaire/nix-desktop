# Base NixOS: the boot loader, the doas and polkit escalation rules, zram, locale, console, and the firewall, on top of the option namespace, the nix settings, the hardening, the persisted state, the packages, the services, and the temp dir mounts beside it.
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
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = true;
    };
    # vm.swappiness=100 is correct with zram: since zram compresses pages in RAM, swapping is cheap.
    # High swappiness lets the kernel aggressively move anonymous pages into zram rather than holding them uncompressed in RAM.
    kernel.sysctl."vm.swappiness" = 100;
  };

  # wheel escalates with doas, with a password, cached per session.
  security.doas = {
    enable = true;
    extraRules = [
      {
        groups = ["wheel"];
        keepEnv = true;
        persist = true;
      }
    ];
  };
  environment.systemPackages = [pkgs.doas-sudo-shim];

  security.polkit.enable = true;

  # Allow wheel group members to reboot and power off without a password prompt.
  environment.etc."polkit-1/rules.d/50-wheel-power.rules".text = ''
    polkit.addRule(function (action, subject) {
      if (
        subject.isInGroup("wheel") &&
        [
          "org.freedesktop.login1.reboot",
          "org.freedesktop.login1.reboot-multiple-sessions",
          "org.freedesktop.login1.power-off",
          "org.freedesktop.login1.power-off-multiple-sessions",
        ].indexOf(action.id) !== -1
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
    priority = 100;
  };

  time.timeZone = lib.mkDefault "UTC";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "C.UTF-8"; # ISO 8601 time format
      LC_MONETARY = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    earlySetup = true;
  };

  networking.firewall.enable = true;
  networking.nftables.enable = true;
}
