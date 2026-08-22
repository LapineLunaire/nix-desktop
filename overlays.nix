# The nixpkgs overlays every instance carries: additions exposes pkgs/ as pkgs.<name>, and modifications overrides packages that need wrapping.
{
  additions = final: _prev: import ./pkgs final;

  modifications = _final: prev: {
    # modules/nixos/desktop sets QT_QPA_PLATFORM to wayland for the session; davinci-resolve and winbox4 are launched with it set to xcb.
    davinci-resolve = prev.symlinkJoin {
      inherit (prev.davinci-resolve) name meta;
      paths = [prev.davinci-resolve];
      nativeBuildInputs = [prev.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/davinci-resolve --set QT_QPA_PLATFORM xcb
      '';
    };

    winbox4 = prev.winbox4.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          wrapProgram $out/bin/WinBox --set QT_QPA_PLATFORM xcb
        '';
    });

    discord = prev.discord.override {
      commandLineArgs = "--force-device-scale-factor=1";
    };
  };
}
