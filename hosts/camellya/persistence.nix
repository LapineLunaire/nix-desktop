# State this host persists beyond the /var that host-base/persistence.nix covers.
{...}: {
  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections"
  ];
}
