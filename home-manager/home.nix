{
  config,
  pkgs,
  ...
}:
let
  homeDirectory = "/Users/hikaru";
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [
      (import (
        builtins.fetchTarball {
          url = "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
        }
      ))
    ];
  };

  home.username = "hikaru";
  home.homeDirectory = homeDirectory;

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    eza
    fd
    mosh
    ripgrep
    deno
    nodejs_22
  ];

  home.file = {
    ".config/nvim".source = mkOutOfStoreSymlink "${homeDirectory}/github.com/tuanemuy/dotfiles/nvim";
    ".config/starship.toml".source =
      mkOutOfStoreSymlink "${homeDirectory}/github.com/tuanemuy/dotfiles/starship.toml";
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;

  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    git = {
      enable = true;
      userName = "tuanemuy";
      userEmail = "22880537+tuanemuy@users.noreply.github.com";
      extraConfig = {
        core = {
          editor = "vim";
          ignorecase = false;
          quotepath = false;
        };
        init = {
          defaultBranch = "main";
        };
      };
      ignores = import ./gitignore.nix;
    };
    neovim = {
      enable = true;
      extraPackages = with pkgs; [
        biome
        prettierd
        markdownlint-cli2
        nil
        nixfmt-rfc-style
        vscode-langservers-extracted
        yaml-language-server
      ];
    };
    tmux = {
      enable = true;
      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.gruvbox;
          extraConfig = "set -g @tmux-gruvbox 'dark'";
        }
        {
          plugin = tmuxPlugins.resurrect;
          extraConfig = "set -g @resurrect-strategy-nvim 'session'";
        }
        {
          plugin = tmuxPlugins.continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '60' # minutes
          '';
        }
      ];
      clock24 = true;
      customPaneNavigationAndResize = true;
      escapeTime = 10;
      keyMode = "vi";
      mouse = true;
      terminal = "screen-256color";
      extraConfig = ''
        set-option -g status-interval 3
        set-option -g status-position top
        set-option -ga terminal-overrides ",xterm-256color:Tc"
        bind c new-window -c '#{pane_current_path}'
      '';
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
    vim.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      defaultKeymap = "viins";
      shellAliases = {
        ls = "eza --icons auto";
        ll = "eza -hlmU --icons --git";
        "md-to-pdf" = "md-to-pdf --config-file ~/.scripts/md-to-pdf/config.js";
      };
      initExtra = ''
        test -e "$HOME"/.iterm2_shell_integration.zsh && source "$HOME"/.iterm2_shell_integration.zsh
        function note() {
            id="$(node ~/.scripts/unique-id/uuidv7.js)"
            title=$1
            if [ -z "$title" ]; then
                title="Note"
            fi
            nvim "$id"_"$title".md
        }
      '';
      profileExtra = ''
        source ~/.orbstack/shell/init.zsh 2>/dev/null || :
      '';
    };
  };
}
