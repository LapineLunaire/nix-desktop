# carmilla's XDG base directories, user directories, and MIME defaults, on Linux only.
{
  config,
  lib,
  pkgs,
  ...
}: let
  zed = "dev.zed.Zed.desktop";
  firefox = "firefox.desktop";

  # Text and source formats another application claims ahead of Zed: okular takes markdown, brave takes xml, nvim takes the source types, and krita takes csv. Formats nothing claims resolve through text/plain.
  editorTypes = [
    "text/plain"
    "text/markdown"
    "text/csv"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/x-java"
    "text/x-makefile"
    "text/x-moc"
    "text/x-pascal"
    "text/x-tex"
    "application/xml"
    "application/x-shellscript"
    "application/x-zerosize"
    "x-scheme-handler/zed"
  ];

  browserTypes = [
    "text/html"
    "application/xhtml+xml"
    "application/x-extension-htm"
    "application/x-extension-html"
    "application/x-extension-shtml"
    "application/x-extension-xhtml"
    "application/x-extension-xht"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/chrome"
  ];

  assign = types: app: lib.genAttrs types (_: app);

  defaultApplications =
    assign editorTypes zed
    // assign browserTypes firefox
    // {
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      "x-scheme-handler/discord-1345366770436800533" = "discord-1345366770436800533.desktop";
      "x-scheme-handler/heroic" = "com.heroicgameslauncher.hgl.desktop";
      "x-scheme-handler/proton-inbox" = "proton-mail.desktop";
      "x-scheme-handler/web+wootwoot" = "wootility.desktop";
      "x-scheme-handler/wootwoot" = "wootility.desktop";
    };

  # The applications each type offers under "Open With", beyond the default above.
  addedAssociations =
    assign editorTypes [zed]
    // assign browserTypes [firefox]
    // {
      "x-scheme-handler/claude-cli" = ["claude-code-url-handler.desktop"];
      "x-scheme-handler/discord-1345366770436800533" = ["discord-1345366770436800533.desktop"];
      "x-scheme-handler/heroic" = ["com.heroicgameslauncher.hgl.desktop" "heroic.desktop"];
      "x-scheme-handler/proton-inbox" = ["proton-mail.desktop" "electron.desktop"];
      "x-scheme-handler/web+wootwoot" = ["wootility.desktop"];
      "x-scheme-handler/wootwoot" = ["wootility.desktop"];
    };

  mimeApps = pkgs.writeText "mimeapps.list" (lib.generators.toINI
    {
      mkKeyValue = key: value: let
        entries =
          if lib.isList value
          then value
          else [value];
      in "${key}=${lib.concatStringsSep ";" entries};";
    }
    {
      "Default Applications" = defaultApplications;
      "Added Associations" = addedAssociations;
    });
in {
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    xdg = {
      enable = true;

      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = "$HOME/desktop";
        documents = "$HOME/documents";
        download = "$HOME/downloads";
        music = "$HOME/music";
        pictures = "$HOME/pictures";
        publicShare = "$HOME/public";
        templates = "$HOME/templates";
        videos = "$HOME/videos";
      };
    };

    # A writable copy, so applications can still register handlers; each rebuild resets it to what this file declares.
    home.activation.mimeApps = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run install -Dm644 ${mimeApps} "${config.xdg.configHome}/mimeapps.list"
    '';
  };
}
