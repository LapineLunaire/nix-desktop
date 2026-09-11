{
  config,
  outputs,
  pkgs,
  ...
}: {
  imports = [
    outputs.nixosModules.host-base
    outputs.nixosModules.binary-cache
    outputs.nixosModules.desktop
    outputs.nixosModules.secure-boot
    ./hardware-configuration.nix
    ./persistence.nix
    ./sops.nix
    ./displays.nix
    ./pipewire.nix
    ./samba-mounts.nix
    ./desktop-packages.nix
  ];

  networking.hostName = "camellya";

  time.timeZone = "Europe/Amsterdam";

  console.keyMap = "colemak";
  services.xserver.xkb = {
    layout = "us,us";
    variant = "colemak,";
    options = "grp:win_space_toggle";
  };

  host.flakePath = "/persist/nix-config";

  # Zen 5. gcc 15.3, the compiler that builds this kernel, resolves -march=native to znver5 on this CPU.
  host.cpu.march = "znver5";

  # The cache the desktop workflow fills, served by the attic guest on sparkle. The key is read off `attic cache info desktop`.
  host.binaryCache = {
    caches = [
      {
        url = "https://cache.lunaire.moe/desktop?priority=10";
        publicKey = "desktop:QBHQfUrDyPKWwQolz4KiaJ1NlC+dGZLP4m29qgvkYs4=";
      }
    ];
    tokenSecret = "attic-pull-token";
  };

  tmpDirs.size = "16G";

  # Compiled for the microarchitecture host.cpu.march names rather than for whatever machine ran the build, so the derivation records the target and the result substitutes. The nvidia module builds against this kernel and becomes cacheable with it.
  boot.kernelPackages = let
    inherit (config.host.cpu) march;
  in
    pkgs.linuxPackages_7_2.extend (
      _: super: {
        kernel = super.kernel.override {
          # Four single-token flags: stdenv word-splits makeFlags, so none may contain a space. KCFLAGS alone is not enough, because arch/x86/Makefile emits -mtune=generic and the top-level Makefile appends KCFLAGS after it; CFLAGS_KERNEL and CFLAGS_MODULE land later still on the compile line, and KRUSTFLAGS covers the Rust objects KCFLAGS never reaches.
          extraMakeFlags = [
            "KCFLAGS=-march=${march}"
            "CFLAGS_KERNEL=-mtune=${march}"
            "CFLAGS_MODULE=-mtune=${march}"
            "KRUSTFLAGS=-Ctarget-cpu=${march}"
          ];
        };
      }
    );

  # With amd_pstate active, powersave lets the firmware (CPPC) handle frequency scaling.
  boot.kernelParams = ["amd_pstate=active"];

  powerManagement.cpuFreqGovernor = "powersave";

  # sshd is closed on the firewall and reachable only from these client subnets: LAN, WireGuard VPN, Nox's LAN, Nox's WireGuard.
  services.openssh.openFirewall = false;
  # winbox discovery reads the MNDP broadcasts that RouterOS sends to UDP 5678, accepted from the LAN only.
  networking.firewall.extraInputRules = ''
    ip saddr { 10.28.64.0/24, 10.28.96.0/24, 10.100.0.0/24, 10.1.0.0/24 } tcp dport 22 accept
    ip saddr 10.28.64.0/24 udp dport 5678 accept
  '';

  # Without a mail relay on this host, smartd reports to the journal only.
  services.smartd.enable = true;
  # smartd references smartmontools but does not add smartctl to PATH.
  environment.systemPackages = [pkgs.smartmontools];

  services.udev.packages = [pkgs.wooting-udev-rules];

  # The nvidia module gates the hardware.nvidia block in hardware-configuration.nix on this list.
  services.xserver.videoDrivers = ["nvidia"];

  system.stateVersion = "26.11";
  home-manager.users.carmilla.home.stateVersion = "26.11";
}
