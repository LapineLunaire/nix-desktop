{pkgs, ...}: {
  imports = [
    ../../modules/nixos/host-base
    ../../modules/nixos/desktop
    ./binary-cache.nix
    ./hardware-configuration.nix
    ./persistence.nix
    ./sops.nix
    ./displays.nix
    ./pipewire.nix
    ./samba-mounts.nix
    ./gaming.nix
  ];

  networking.hostName = "camellya";

  host.flakePath = "/persist/nix-config";

  # An explicit target lets other machines build and cache the kernel.
  boot.kernelPackages = let
    march = "znver5";
  in
    pkgs.linuxPackages_7_2.extend (_: prev: {
      kernel = prev.kernel.override {
        # Keep each make flag one shell word. The later CFLAGS override -mtune=generic;
        # Rust objects need their own target flag.
        extraMakeFlags = [
          "KCFLAGS=-march=${march}"
          "CFLAGS_KERNEL=-mtune=${march}"
          "CFLAGS_MODULE=-mtune=${march}"
          "KRUSTFLAGS=-Ctarget-cpu=${march}"
        ];
      };
    });

  # Let CPPC manage frequency scaling.
  boot.kernelParams = ["amd_pstate=active"];

  powerManagement.cpuFreqGovernor = "powersave";

  # Allow SSH from the LANs and VPNs below.
  # WinBox discovery (UDP 5678) is LAN-only.
  networking.firewall.extraInputRules = ''
    ip saddr { 10.28.64.0/24, 10.28.96.0/24, 10.100.0.0/24, 10.1.0.0/24 } tcp dport 22 accept
    ip saddr 10.28.64.0/24 udp dport 5678 accept
  '';

  services.udev.packages = [pkgs.wooting-udev-rules];

  services.xserver.videoDrivers = ["nvidia"];
  programs.obs-studio.package = pkgs.obs-studio.override {cudaSupport = true;};

  system.stateVersion = "26.11";
  home-manager.users.carmilla.home.stateVersion = "26.11";
}
