{
  additions = final: _prev: import ./pkgs final;

  modifications = _final: prev: {
    # These applications need XWayland despite the session-wide Wayland default.
    davinci-resolve = prev.symlinkJoin {
      inherit (prev.davinci-resolve) name meta;
      paths = [prev.davinci-resolve];
      nativeBuildInputs = [prev.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/davinci-resolve --set QT_QPA_PLATFORM xcb
      '';
    };

    winbox4 =
      if prev.stdenv.hostPlatform.isLinux
      then
        prev.winbox4.overrideAttrs (old: {
          postInstall =
            (old.postInstall or "")
            + ''
              wrapProgram $out/bin/WinBox --set QT_QPA_PLATFORM xcb
            '';
        })
      else prev.winbox4;

    discord = prev.discord.override {
      commandLineArgs = "--force-device-scale-factor=1";
    };
  };
}
