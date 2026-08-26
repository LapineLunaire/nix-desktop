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
    # The download URL is unversioned; .forgejo/workflows/tibia-update.yml refreshes the hash below nightly.
    version = "unstable";

    # static.tibia.com sits behind Cloudflare, which answers 403 to a request that omits an Accept-Encoding header. --compressed sends one and decodes the response, matching what nix-prefetch-url does, so the hash stays the one that tool prints.
    src = fetchurl {
      url = "https://static.tibia.com/download/tibia.x64.tar.gz";
      curlOptsList = ["--compressed"];
      sha256 = "015ill2vs30q5ravljf313cijn0y2lp4gw3czf3lj9y4hbgsbgsd";
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

  # The client's qt.conf sets Prefix=., so the working directory has to be the payload for its plugins and bundled Qt libs to resolve.
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

    # Overrides the wayland QT_QPA_PLATFORM that modules/nixos/desktop sets for the session.
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
