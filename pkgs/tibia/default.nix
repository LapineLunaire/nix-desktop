{
  lib,
  buildFHSEnv,
  fetchurl,
  icoutils,
  makeDesktopItem,
  stdenvNoCC,
  writeShellScript,
  # System libs
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
    # The download URL is unversioned; update the hash when upstream releases a new client.
    version = "unstable";

    # static.tibia.com sits behind Cloudflare, which challenges requests that omit an Accept-Encoding header. --compressed sends one and decodes the response, matching what nix's own downloader does for nix-prefetch-url so the hash below stays the one that tool prints.
    src = fetchurl {
      url = "https://static.tibia.com/download/tibia.x64.tar.gz";
      curlOptsList = ["--compressed"];
      sha256 = "0wypyx71c5zzr030514l1awv6ds8p2cdp3ghybczmh6y15mvzwhs";
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

  desktopItem = makeDesktopItem {
    name = "tibia";
    desktopName = "Tibia";
    comment = "Tibia MMORPG client";
    exec = "tibia";
    icon = "tibia";
    categories = ["Game"];
  };

  # Change into the tibia directory before launching so qt.conf (Prefix=.) resolves plugins and bundled Qt libs correctly relative to the binary.
  startScript = writeShellScript "tibia-start" ''
    export LD_LIBRARY_PATH="${tibia-unwrapped}/opt/tibia/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    cd ${tibia-unwrapped}/opt/tibia
    exec ./Tibia "$@"
  '';
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

    # Force XCB; Tibia's client has known issues with Wayland compositors.
    profile = ''
      export QT_QPA_PLATFORM=xcb
      unset WAYLAND_DISPLAY
    '';

    runScript = startScript;

    extraInstallCommands = ''
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
