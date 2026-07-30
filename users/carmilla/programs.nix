# carmilla's home-manager programs: the shell, git, the editors, the terminal, and the tooling around them.
{
  config,
  lib,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    PAGER = "nvimpager";
    MANPAGER = "nvimpager";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Lapine";
        email = "lapine@lunaire.eu";
        signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_rk_lapine";
      };
      core = {
        editor = "nvim";
        pager = "nvimpager";
      };
      gpg.format = "ssh";
      commit.gpgsign = true;
      tag.gpgsign = true;
      pull.rebase = true;
      init.defaultBranch = "main";
      color.ui = "auto";
      push.autoSetupRemote = true;
      rerere.enabled = true; # remember conflict resolutions
      diff.algorithm = "histogram"; # better diff output than default myers
      merge.conflictstyle = "zdiff3"; # shows base version in conflict markers
      branch.sort = "-committerdate";
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "TTY";
      theme_background = false;
      truecolor = true;
      vim_keys = true;
      update_ms = 1000;
    };
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      modules = [
        "title"
        "separator"
        "os"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "terminal"
        "terminalfont"
        "wm"
        "wmtheme"
        {
          type = "display";
          compactType = "original";
        }
        "cpu"
        "gpu"
        {
          type = "memory";
          format = "{} / {}";
        }
        {
          type = "disk";
          folders = "/";
        }
        {
          type = "disk";
          folders = "/nix";
        }
        "localip"
        "break"
        "colors"
      ];
    };
  };

  programs.nixvim = {
    enable = true;
    # Reuse the host's nixpkgs instance instead of letting nixvim instantiate its own from its pinned source.
    nixpkgs.pkgs = pkgs;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    opts = {
      number = true;
      relativenumber = true;
      signcolumn = "yes";
      termguicolors = true;
      undofile = true;
      clipboard = "unnamedplus";
    };

    colorschemes.gruvbox = {
      enable = true;
      settings.contrast = "hard";
    };

    # nvim-lspconfig supplies the default server definitions (cmd, filetypes, root markers) that lsp.servers.* activates.
    plugins.lspconfig.enable = true;
    lsp.servers.nixd = {
      enable = true;
      config.settings.nixd.formatting.command = ["alejandra"];
    };

    # Formats on save: alejandra for nix buffers, the attached LSP for everything else.
    plugins.conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft.nix = ["alejandra"];
        format_on_save.lsp_format = "fallback";
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # home-manager deprecated the implicit default config block; declare everything explicitly instead
    # Rebuild OpenSSH with FIDO2 support for sk-ssh-ed25519 resident keys stored on the YubiKey.
    package = pkgs.openssh.override {withFIDO = true;};
    settings."*" = {
      identityFile = [
        "~/.ssh/id_ed25519_sk_rk_lapine"
        "~/.ssh/id_ed25519_sk_rk_lapine2"
      ];
      identitiesOnly = true;
    };
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings.manager = {
      show_hidden = true;
      sort_by = "natural";
      sort_dir_first = true;
    };
  };

  programs.zed-editor = {
    enable = true;
    userSettings = {
      telemetry.metrics = false;
      load_direnv = "shell_hook";
      vim_mode = true;
      hour_format = "hour24";
      theme = {
        mode = "dark";
        dark = "Gruvbox Dark Hard";
        light = "Gruvbox Light Hard";
      };
      languages.Nix.language_servers = [
        "nixd"
        "!nil"
      ];
      lsp.nixd.settings = {
        nixpkgs.expr = "import <nixpkgs> {}";
        formatting.command = ["alejandra"];
      };
    };
    extensions = ["nix" "gruvbox"];
  };

  programs.ghostty = {
    enable = true;
    # nixpkgs builds ghostty from source on Linux only; ghostty-bin unpacks the official macOS release, which targets.darwin.copyApps copies into ~/Applications.
    package =
      if pkgs.stdenv.hostPlatform.isDarwin
      then pkgs.ghostty-bin
      else pkgs.ghostty;
    settings = {
      theme = "Gruvbox Dark Hard";
      background-opacity = 0.95;
      window-padding-x = 8;
      window-padding-y = 8;
      # Ghostty's macOS updater cannot replace an app bundle that lives in the read-only store.
      auto-update = "off";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    history = {
      path = "${config.xdg.dataHome}/zsh/history";
      share = true;
    };
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      setopt extendedglob nomatch
      unsetopt beep
      bindkey -v

      PROMPT='%B%F{blue}%m %F{magenta}%~ %F{blue}λ %b%f'
    '';
    shellAliases =
      {
        pk = "pkill";
        cat = "bat";
        ls = "eza";
        ll = "eza -l";
        la = "eza -la";
        tree = "eza --tree";
        grep = "grep --color=auto";
        egrep = "egrep --color=auto";
        fgrep = "fgrep --color=auto";
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        # Use CoW reflinks on supported filesystems (ZFS, btrfs), falling back to a regular copy. --sparse=always avoids writing zero blocks explicitly.
        cp = "cp --reflink=auto --sparse=always";
        # Derive the sops age key on the fly from the SSH host key. Requires elevated privileges to read /etc/ssh/ssh_host_ed25519_key.
        sops = "SOPS_AGE_KEY_FILE=<(doas cat /etc/ssh/ssh_host_ed25519_key | ssh-to-age -private-key) sops";
      };
  };
}
