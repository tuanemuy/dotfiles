{
  config,
  pkgs,
  ...
}:
let
  username = "hikaru";
  homeDirectory = "/home/${username}";
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
      (final: prev: {
        folly = prev.folly.overrideAttrs (old: {
          doCheck = false;
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [
            "-DBUILD_TESTS=OFF"
          ];
        });
        fizz = prev.fizz.overrideAttrs (old: {
          doCheck = false;
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [
            "-DBUILD_TESTS=OFF"
          ];
        });

      })
    ];
  };

  home = {
    inherit username;
    inherit homeDirectory;
  };

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    deno
    eternal-terminal
    eza
    fd
    gcc
    gh
    imagemagick
    nodejs_24
    pm2
    ripgrep
    tree-sitter
    watchman
  ];

  imports = [
    ./llm-agents.nix
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
    ".claude/skills".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/skills";
  };

  home.sessionVariables = {
  };

  programs =
    pkgs.lib.genAttrs
      [
        "home-manager"
        "bat"
        "bottom"
        "direnv"
        "fzf"
        "git"
        "lazygit"
        "neovim"
        "tmux"
        "starship"
        "vim"
        "zsh"
        "zoxide"
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
