# Lanzaboote secure boot for hosts with an enrolled key set, replacing systemd-boot: it owns the sbctl PKI bundle's directory, its persistence entry, and the sbctl and TPM2 tooling.
{pkgs, ...}: let
  pkiBundle = "/var/lib/sbctl";
in {
  boot.loader.systemd-boot.enable = false;

  boot.lanzaboote = {
    inherit pkiBundle;
    enable = true;
  };

  # sbctl create-keys writes into the bundle directory, so pre-create it with restrictive modes and persist it across reboots.
  systemd.tmpfiles.rules = [
    "d '${pkiBundle}' 0700 root root - -"
    "z '${pkiBundle}' 0700 root root - -"
  ];
  environment.persistence."/persist".directories = [pkiBundle];

  environment.systemPackages = with pkgs; [
    sbctl
    tpm2-tools
  ];

  # tctiEnvironment sets TPM2TOOLS_TCTI so tpm2-tools commands work without explicitly specifying a TCTI string.
  security.tpm2 = {
    enable = true;
    tctiEnvironment.enable = true;
  };
}
