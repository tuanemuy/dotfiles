{
  inputs,
  config,
  pkgs,
  gitDirectory,
  ...
}:
let
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    cocoapods
    deno
    eza
    fd
    gh
    imagemagick
    pm2
    ripgrep
    watchman
    nodejs_24
  ];

  imports = [
    ./llm-agents.nix
    ./containers.nix
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
    "biome.json".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/biome.json";
    ".claude/settings.json".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/settings.json";
    ".claude/statusline-command.sh".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/statusline-command.sh";
    ".claude/skills".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/skills";
    ".aerospace.toml".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/aerospace.toml";
  }
  // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
    "Library/Fonts/.home-manager-fonts-version".enable = false;
  };

  home.sessionVariables = {
  };

  programs =
    pkgs.lib.genAttrs
      [
        "home-manager"
        "bat"
        "bottom"
        "delta"
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
          inherit inputs;
          inherit config;
          inherit pkgs;
          inherit gitDirectory;
        }
      );
}
