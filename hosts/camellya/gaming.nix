{inputs, ...}: {
  imports = [inputs.self.nixosModules.gaming];

  # The Steam Frame wireless adapter uses 6 GHz, which the world regulatory domain disables.
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NL
  '';

  systemd.network.links."10-steam-frame" = {
    matchConfig.Property = ["ID_VENDOR_ID=28de" "ID_MODEL_ID=2432"];
    linkConfig.Name = "wlframe";
  };

  # Steam Frame discovery and streaming, from the LAN or the Frame's wireless adapter.
  networking.firewall.extraInputRules = ''
    ip saddr 10.28.64.0/24 tcp dport { 27036, 27037 } accept
    ip saddr 10.28.64.0/24 udp dport { 10400, 10401, 27031-27036 } accept
    iifname "wlframe" tcp dport { 27036, 27037 } accept
    iifname "wlframe" udp dport { 10400, 10401, 27031-27036 } accept
  '';
}
