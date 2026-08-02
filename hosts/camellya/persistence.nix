# Host directories on top of the impermanence baseline in modules/nixos/host-base/persistence.nix.
{...}: {
  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections"
  ];
}
