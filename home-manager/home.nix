{
  inputs,
  config,
  lib,
  pkgs,
  gitDirectory,
  ...
}:
let
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.stateVersion = "24.11";

  home.packages =
    with pkgs;
    [
      deno
      eza
      fd
      ffmpeg
      gh
      imagemagick
      pm2
      python314
      ripgrep
      nodejs_24
      uv
    ]
    ++ [
      (pkgs.callPackage ./packages/rinkaku.nix { })
    ]
    ++ lib.optionals stdenv.isDarwin [
      cocoapods
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
    ".claude/worktree-setup.sh".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/worktree-setup.sh";
    ".codex/config.toml".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/codex/config.toml";
    ".claude/skills".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/agents/skills";
    ".agents/skills".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/agents/skills";
    ".aerospace.toml".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/aerospace.toml";
    ".agent-browser/config.json".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/agent-browser.json";
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
          inherit inputs;
          inherit config;
          inherit pkgs;
          inherit gitDirectory;
        }
      );
}
