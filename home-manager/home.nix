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

  home.packages = with pkgs; [
    cocoapods
    deno
    eternal-terminal
    eza
    fd
    ffmpeg
    gh
    imagemagick
    pm2
    ripgrep
    nodejs_24
    inputs.herdr.packages.${pkgs.system}.default
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
    ".config/herdr/config.toml".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/herdr/config.toml";
    ".config/.markdownlint-cli2.jsonc".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/markdownlint-cli2.jsonc";
    "biome.json".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/biome.json";
    ".claude/settings.json".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/settings.json";
    ".claude/statusline-command.sh".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/claude/statusline-command.sh";
    ".claude/skills".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/agents/skills";
    ".agents/skills".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/agents/skills";
    ".aerospace.toml".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/aerospace.toml";
    ".agent-browser/config.json".source =
      mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/agent-browser.json";
  };

  # Codex rewrites ~/.codex/config.toml at runtime to persist per-project trust,
  # NUX counters, and hook hashes, and it offers no include/layering mechanism to
  # keep that state out of the file. Symlinking would push those writes into this
  # public repo, so copy the static config in as a real file instead and let the
  # runtime state accumulate only in $HOME. The hash stamp keeps a routine switch
  # from wiping that state — the copy happens only when the static config changes.
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="${gitDirectory}/dotfiles/config/codex/config.toml"
    dst="$HOME/.codex/config.toml"
    stamp="$HOME/.codex/.config.toml.hm-hash"
    hash=$(${pkgs.coreutils}/bin/sha256sum "$src" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
    if [ ! -e "$dst" ] || [ "$(cat "$stamp" 2>/dev/null)" != "$hash" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.codex"
      $DRY_RUN_CMD rm -f "$dst"
      $DRY_RUN_CMD cp "$src" "$dst"
      $DRY_RUN_CMD chmod u+w "$dst"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/tee "$stamp" <<< "$hash" > /dev/null
    fi
  '';

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
