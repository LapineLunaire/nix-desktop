# carmilla's home packages: the set every host gets, plus the darwin-only and Linux-only additions.
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
      ffmpeg-full
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
        dino
        discord
        fluffychat
        heroic
        high-tide
        kaidan
        minisign
        mission-center
        mpv
        pciutils
        prismlauncher
        tibia
        traceroute
        usbutils
        wootility
        xivlauncher
      ]
    );
}
