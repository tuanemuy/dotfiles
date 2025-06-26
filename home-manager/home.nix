{
  config,
  pkgs,
  ...
}:
let
  username = "hikaru";
  homeDirectory = "/Users/${username}";
  gitDirectory = "${homeDirectory}/github.com/tuanemuy";
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

  home = {
    inherit username;
    inherit homeDirectory;
  };

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    claude-code
    deno
    eternal-terminal
    eza
    fd
    gh
    imagemagick
    pm2
    ripgrep
    watchman
    nodejs_24
  ];

  home.file = {
    ".config/nvim".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/nvim";
    ".config/starship.toml".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/starship.toml";
    ".wezterm.lua".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/wezterm.lua";
    ".config/ghostty/config".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/ghostty.config";
    ".config/.markdownlint-cli2.jsonc".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/markdownlint-cli2.jsonc";
    "biome.json".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/biome.json";
    ".claude/settings.json".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/settings.json";
  };

  home.sessionVariables = {
  };

  programs =
    pkgs.lib.genAttrs
      [
        "home-manager"
        "direnv"
        "fzf"
        "git"
        "lazygit"
        "neovim"
        "tmux"
        "starship"
        "vim"
        "zsh"
      ]
      (
        program:
        import ./programs/${program}.nix {
          inherit pkgs;
          inherit gitDirectory;
        }
      );

  systemd.user.services.et =
    if pkgs.stdenv.isDarwin then
      null
    else
      {
        Unit = {
          Description = "Eternal Terminal server";
          After = [ "network.target" ];
        };
        Service = {
          ExecStart = "${pkgs.eternal-terminal}/bin/etserver";
          Restart = "always";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

  launchd.agents.et =
    if pkgs.stdenv.isDarwin then
      {
        enable = true;
        config = {
          Label = "com.nix.etserver";
          ProgramArguments = [ "${pkgs.eternal-terminal}/bin/etserver" ];
          KeepAlive = true;
          RunAtLoad = true;
        };
      }
    else
      null;
}
