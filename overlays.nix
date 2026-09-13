{
  additions = final: _prev: import ./pkgs final;

  modifications = _final: prev: {
    # These applications need XWayland despite the session-wide Wayland default.
    davinci-resolve = let
      repinned = prev.davinci-resolve.override {
        runCommandLocal = name: env: script:
          prev.runCommandLocal name (env // {outputHash = "sha256-+3SB32EHpH9/0hM3h8CrO6f7V4ZAmxUFh3P8m6QDeO0=";}) script;
      };
    in
      prev.symlinkJoin {
        inherit (repinned) name meta;
        paths = [repinned];
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
