{
  config,
  lib,
  ...
}: {
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "thunderbolt"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = ["kvm-amd"];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=2G"
      "mode=755"
    ];
  };

  # LUKS2 container "cryptroot" holds an LVM VG "camellya" with xfs volumes for /nix, /persist, and /home.
  # tpm2-device=auto unlocks from the TPM2 token in the LUKS header, with the passphrase keyslot as fallback.
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/d72ac9db-b522-4087-8352-fdf216090ed5";
    crypttabExtraOpts = ["tpm2-device=auto"];
    allowDiscards = true;
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/c15c5510-5098-41f0-b292-65b9cea700e1";
    fsType = "xfs";
    options = ["noatime"];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/5937a495-830f-4f76-bca2-1124487ce8c1";
    fsType = "xfs";
    options = ["noatime" "nosuid" "nodev"];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/213e2b4b-5f4e-400f-9b43-fd828e5894ca";
    fsType = "xfs";
    options = ["noatime" "nosuid" "nodev"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/15B1-29E4";
    fsType = "vfat";
    options = ["umask=0077"];
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # The nvidia module applies this block only when services.xserver.videoDrivers lists "nvidia", which default.nix does.
  hardware.nvidia = {
    # Modesetting is required for the Wayland session.
    modesetting.enable = true;
    # Blackwell (RTX 50-series) is supported by the open kernel modules.
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    powerManagement.enable = true;
  };
}
