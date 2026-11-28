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
  biomeConfigHome =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support"
    else
      config.xdg.configHome;
  # Uploading attachments to PRs and issues requires gh 2.99.0 or later.
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  home.stateVersion = "24.11";

  home.packages =
    with pkgs;
    [
      bitwarden-cli
      deno
      eza
      fd
      ffmpeg
      imagemagick
      pm2
      python314
      ripgrep
      nodejs_24
      uv
    ]
    ++ [
      (pkgs.callPackage ./packages/git-wt.nix { })
      (pkgs.callPackage ./packages/rinkaku.nix { })
      unstable.gh
    ]
    ++ lib.optionals stdenv.isDarwin [
      cocoapods
    ];

  imports = [
    ./llm-agents.nix
    ./containers.nix
  ];

  home.file = {
    ".npmrc".text = ''
      prefix=~/.npm_global
    '';
    ".config/nvim".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/nvim";
    ".config/starship.toml".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/starship.toml";
    ".wezterm.lua".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/wezterm.lua";
    ".config/ghostty/config".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/ghostty.config";
    ".config/.markdownlint-cli2.jsonc".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/markdownlint-cli2.jsonc";
    # Biome resolves VCS settings relative to the configuration directory.
    "${biomeConfigHome}/biome/biome.json".text = builtins.toJSON (
      builtins.removeAttrs (builtins.fromJSON (builtins.readFile ../biome.json)) [ "vcs" ]
      // { "$schema" = unstable.biome.jsonschema; }
    );
    ".claude/settings.json".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/settings.json";
    ".claude/statusline-command.sh".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/statusline-command.sh";
    ".claude/worktree-setup.sh".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/worktree-setup.sh";
    ".claude/archive-hook.sh".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/archive-hook.sh";
    ".claude/archive-run.sh".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/archive-run.sh";
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
