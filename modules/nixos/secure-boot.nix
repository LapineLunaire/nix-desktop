# Lanzaboote secure boot for hosts with an enrolled key set, replacing systemd-boot: the sbctl PKI bundle's path and the sbctl and TPM2 tooling. sbctl create-keys makes the directory at bootstrap, and it persists as part of /var/lib in host-base/persistence.nix.
{pkgs, ...}: let
  pkiBundle = "/var/lib/sbctl";
in {
  boot.loader.systemd-boot.enable = false;

  boot.lanzaboote = {
    inherit pkiBundle;
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    sbctl
    tpm2-tools
  ];

  # tctiEnvironment sets TPM2TOOLS_TCTI so tpm2-tools commands work without explicitly specifying a TCTI string.
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
}
