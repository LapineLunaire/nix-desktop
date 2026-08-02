# CIFS mounts of sparkle's samba shares, authenticated via the sops-rendered samba-credentials file. Mounted on first access (noauto + x-systemd.automount) and unmounted after 60s idle. Kept out of hardware-configuration.nix so regenerating it does not drop them.
{
  config,
  pkgs,
  ...
}: let
  carmilla = config.users.users.carmilla;
in {
  # mount.cifs, needed to mount the shares below.
  environment.systemPackages = [pkgs.cifs-utils];

  fileSystems =
    builtins.mapAttrs (_: share: {
      device = "//sparkle.lunaire.moe/${share}";
      fsType = "cifs";
      options = [
        "credentials=${config.sops.templates."samba-credentials".path}"
        "uid=${toString carmilla.uid}"
        "gid=${toString config.users.groups.${carmilla.group}.gid}"
        "seal"
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
