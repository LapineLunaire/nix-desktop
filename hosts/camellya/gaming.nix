{inputs, ...}: {
  imports = [inputs.aagl.nixosModules.default];

  virtualisation.waydroid.enable = true;

  # Wine/Proton synchronization support.
  boot.kernelModules = ["ntsync"];

  # The Steam Frame wireless adapter uses 6 GHz, which the world regulatory domain disables.
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=NL
  '';

  # Steam Frame discovery and streaming, from the LAN or the Frame's wireless adapter.
  networking.firewall.extraInputRules = ''
    ip saddr 10.28.64.0/24 tcp dport { 27036, 27037 } accept
    ip saddr 10.28.64.0/24 udp dport { 10400, 10401, 27031-27036 } accept
    iifname "wl*" tcp dport { 27036, 27037 } accept
    iifname "wl*" udp dport { 10400, 10401, 27031-27036 } accept
  '';

  environment.sessionVariables = {
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_ENABLE_HDR = "1";
  };

  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.anime-games-launcher.enable = true;
  programs.honkers-railway-launcher.enable = true;
}
