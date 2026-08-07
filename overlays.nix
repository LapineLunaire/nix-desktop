# The overlays every nixpkgs instance in this flake carries: additions brings pkgs/ into scope, modifications overrides packages nixpkgs already ships.
{
  additions = final: _prev: import ./pkgs final;

  modifications = _final: prev: {
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
