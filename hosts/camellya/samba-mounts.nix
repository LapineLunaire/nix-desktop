# CIFS mounts of the shares vault.lunaire.moe serves. Kept out of hardware-configuration.nix so regenerating that file does not drop them.
{
  config,
  pkgs,
  ...
}: {
  # mount.cifs, which the mounts below need.
  environment.systemPackages = [pkgs.cifs-utils];

  fileSystems = let
    carmilla = config.users.users.carmilla;
  in
    builtins.mapAttrs (_: share: {
      device = "//vault.lunaire.moe/${share}";
      fsType = "cifs";
      options = [
        "credentials=${config.sops.templates."samba-credentials".path}"
        "uid=${toString carmilla.uid}"
        "gid=${toString config.users.groups.${carmilla.group}.gid}"
        "seal"
        "nosuid"
        "nodev"
        "noexec"
        "_netdev"
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
      ];
    }) {
      "/home/carmilla/vault" = "carmilla";
      "/home/carmilla/torrents" = "torrents";
    };
}
