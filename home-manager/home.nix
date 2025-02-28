{
  config,
  pkgs,
  ...
}:
let
  username = "hikaru";
  homeDirectory = "/Users/${username}";
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
    mosh
    ripgrep
    deno
    nodejs_22
  ];

  home.file = {
    ".config/nvim".source = mkOutOfStoreSymlink "${homeDirectory}/github.com/tuanemuy/dotfiles/config/nvim";
    ".config/starship.toml".source =
      mkOutOfStoreSymlink "${homeDirectory}/github.com/tuanemuy/dotfiles/config/starship.toml";
  };

  home.sessionVariables = {
  };

  programs = pkgs.lib.genAttrs [
    "home-manager"
    "direnv"
    "fzf"
    "git"
    "neovim"
    "tmux"
    "starship"
    "vim"
    "zsh"
  ] (program: import ./programs/${program}.nix { inherit pkgs; });
}
