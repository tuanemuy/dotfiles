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
    "biome.json".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/biome.json";
    ".claude/settings.json".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/settings.json";
    ".claude/skills".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/skills";
    ".aerospace.toml".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/aerospace.toml";
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
          inherit inputs;
          inherit config;
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
