{
  lib,
  buildFHSEnv,
  fetchurl,
  icoutils,
  makeDesktopItem,
  stdenvNoCC,
  writeShellScript,
  alsa-lib,
  brotli,
  dbus,
  expat,
  fontconfig,
  freetype,
  libdrm,
  libglvnd,
  libx11,
  libxcb,
  libxcb-cursor,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-util,
  libxcb-wm,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  openssl,
  stdenv,
  vulkan-loader,
  wayland,
  zlib,
}: let
  tibia-unwrapped = stdenvNoCC.mkDerivation {
    pname = "tibia-unwrapped";
    # The nightly workflow updates the hash of this unversioned download.
    version = "unstable";

    # The server requires Accept-Encoding. Match nix-prefetch-url's decoded response.
    src = fetchurl {
      url = "https://static.tibia.com/download/tibia.x64.tar.gz";
      curlOptsList = ["--compressed"];
      sha256 = "0f0as41wcw8raz74kxxbfalykl5zjaighxpn8blw337zy74wv43a";
    };

    dontBuild = true;
    dontConfigure = true;
    dontStrip = true;
    dontPatchELF = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/opt/tibia
      cp -r . $out/opt/tibia/
      runHook postInstall
    '';
  };
in
  buildFHSEnv {
    name = "tibia";

    targetPkgs = _: [
      alsa-lib
      brotli
      dbus
      expat
      fontconfig
      freetype
      libdrm
      libglvnd
      libx11
      libxcb
      libxcb-cursor
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-util
      libxcb-wm
      libxkbcommon
      mesa
      nspr
      nss
      openssl
      stdenv.cc.cc.lib
      vulkan-loader
      wayland
      zlib
    ];

    # The bundled Qt client needs XWayland.
    profile = ''
      export QT_QPA_PLATFORM=xcb
      unset WAYLAND_DISPLAY
    '';

    # qt.conf uses Prefix=.; run from the payload directory.
    runScript = writeShellScript "tibia-start" ''
      export LD_LIBRARY_PATH="${tibia-unwrapped}/opt/tibia/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      cd ${tibia-unwrapped}/opt/tibia
      exec ./Tibia "$@"
    '';

    extraInstallCommands = let
      desktopItem = makeDesktopItem {
        name = "tibia";
        desktopName = "Tibia";
        comment = "Tibia MMORPG client";
        exec = "tibia";
        icon = "tibia";
        categories = ["Game"];
      };
    in ''
      install -Dm444 ${desktopItem}/share/applications/*.desktop -t $out/share/applications
      ${icoutils}/bin/icotool -x --width=256 ${tibia-unwrapped}/opt/tibia/tibia.ico -o $TMPDIR
      install -Dm444 $TMPDIR/tibia_*.png $out/share/icons/hicolor/256x256/apps/tibia.png
    '';

    meta = {
      description = "Tibia MMORPG client";
      homepage = "https://www.tibia.com";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "tibia";
    };
  }
