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
    eza
    fd
    imagemagick
    mosh
    ripgrep
    deno
    nodejs_22
  ];

  home.file = {
    ".config/nvim".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/nvim";
    ".config/starship.toml".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/starship.toml";
    ".wezterm.lua".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/wezterm.lua";
    ".config/ghostty/config".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/ghostty.config";
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
}
