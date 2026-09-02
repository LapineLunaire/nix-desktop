# carmilla's home-manager programs: the shell, the terminal tooling, the editors, and the desktop applications they configure.
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

  programs.claude-code = {
    enable = true;
    settings.includeCoAuthoredBy = false;
    plugins.superpowers = pkgs.fetchFromGitHub {
      owner = "obra";
      repo = "superpowers";
      rev = "b36e0829c6d0140e93cfef2ca599b1b07d4a7797";
      hash = "sha256-EsGNO0dULWf5Bx6bGrCv2kI2Z8aKH0kRvGiuN23wChQ=";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Carmilla";
        email = "carmilla@lunaire.eu";
        signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_rk_carmilla";
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
      rerere.enabled = true;
      diff.algorithm = "histogram";
      merge.conflictstyle = "zdiff3"; # zdiff3 includes the merge base in conflict markers
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
    # Reuse the host's nixpkgs instance for nixvim's packages.
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
    # home-manager warns while enableDefaultConfig is true and will drop the implicit default block.
    enableDefaultConfig = false;
    package = pkgs.openssh;
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
    settings.mgr = {
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

  programs.zoxide.enable = true;

  programs.zsh = {
    enable = true;
    history.path = "${config.xdg.dataHome}/zsh/history";
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
        # --reflink=auto uses CoW where the filesystem supports it and copies otherwise; --sparse=always skips writing blocks of zeroes.
        cp = "cp --reflink=auto --sparse=always";
        # Derives the sops age key from the SSH host key, which needs elevated privileges to read.
        sops = "SOPS_AGE_KEY=\"$(doas cat /etc/ssh/ssh_host_ed25519_key | ssh-to-age -private-key)\" sops";
      };
  };
}
