# Lanzaboote for hosts with an enrolled key set. sbctl create-keys makes the PKI bundle at bootstrap, under the /var/lib that host-base/persistence.nix persists.
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

  # tctiEnvironment sets TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI, so the tooling reaches the TPM without a TCTI string on each command.
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
}
