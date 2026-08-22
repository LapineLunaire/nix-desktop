# carmilla's home packages: the tooling shared by every system, then the darwin-only and Linux-only additions.
{
  lib,
  pkgs,
  ...
}: {
  home.packages =
    (with pkgs; [
      alejandra
      azahar
      bat
      brave
      curl
      duf
      eza
      fd
      ffmpeg
      firefox
      gping
      iperf3
      jq
      ldns
      megatools
      mtr
      nixd
      nmap
      nvimpager
      pandoc
      proton-vpn
      protonmail-desktop
      rclone
      ripgrep
      rsync
      socat
      sops
      ssh-to-age
      texliveFull
      whois
      winbox4
      xh
      yt-dlp
      yubikey-manager
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
      with pkgs; [
        iina
        utm
      ]
    )
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      with pkgs; [
        davinci-resolve
        dino
        discord
        fluffychat
        heroic
        high-tide
        kaidan
        krita
        minisign
        mission-center
        mpv
        pciutils
        prismlauncher
        protonplus
        tibia
        traceroute
        usbutils
        wootility
        xivlauncher
      ]
    );
}
