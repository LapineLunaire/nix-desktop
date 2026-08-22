{
  lib,
  outputs,
  pkgs,
  ...
}: {
  imports = [
    outputs.nixosModules.host-base
    outputs.nixosModules.desktop
    outputs.nixosModules.secure-boot
    ./hardware-configuration.nix
    ./persistence.nix
    ./sops.nix
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

  tmpDirs.size = "16G";

  # A kernel rebuilt with X86_NATIVE_CPU, which detects the CPU it is compiled on: camellya must be built on itself.
  boot.kernelPackages = pkgs.linuxPackages_7_2.extend (
    _: super: {
      kernel = super.kernel.override {
        structuredExtraConfig = {
          X86_NATIVE_CPU = lib.kernel.yes;
        };
      };
    }
  );

  # With amd_pstate active, powersave lets the firmware (CPPC) handle frequency scaling.
  boot.kernelParams = ["amd_pstate=active"];

  powerManagement.cpuFreqGovernor = "powersave";

  # sshd is closed on the firewall and reachable only from these client subnets: LAN, WireGuard VPN, Nox's LAN, Nox's WireGuard.
  services.openssh.openFirewall = false;
  networking.firewall.extraInputRules = ''
    ip saddr { 10.28.64.0/24, 10.28.96.0/24, 10.100.0.0/24, 10.1.0.0/24 } tcp dport 22 accept
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
