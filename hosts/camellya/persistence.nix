{...}: {
  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections"
  ];
}
