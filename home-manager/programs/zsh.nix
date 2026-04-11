{
  config,
  pkgs,
  gitDirectory,
  ...
}:
{
  enable = true;
  enableCompletion = true;
  autosuggestion.enable = true;
  defaultKeymap = "viins";
  shellAliases =
    let
      flakeDir = "${config.home.homeDirectory}/.config/home-manager";
    in
    {
      nix-switch = "nix run ${flakeDir}#switch && exec zsh";
      nix-update = "nix run ${flakeDir}#update";
      nix-up = "nix run ${flakeDir}#up && exec zsh";
      nix-clean = "nix run ${flakeDir}#clean";
      ls = "eza --icons";
      ll = "eza -lhmU --icons --git";
      lt = "eza --icons --tree -L";
      dark = "chth dark";
      light = "chth light";
      autoth = "chth auto";
    }
    // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    };
  plugins = [
    {
      name = "zsh-abbr";
      src = "${pkgs.zsh-abbr}/share/zsh/zsh-abbr";
    }
    {
      name = "fast-syntax-highlighting";
      src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
    }
  ];
  sessionVariables = {
    GIT_DIRECTORY = gitDirectory;
  };
  initContent = pkgs.lib.mkMerge [
    (pkgs.lib.mkBefore ''
      ${import ../workarounds/starship.nix}
    '')
    (pkgs.lib.mkAfter ''
      export LANG=ja_JP.UTF-8
      export CURRENT_THEME="light"
      export GIT_DIRECTORY=${gitDirectory}
      export PATH=$PATH:$(npm prefix --location=global)/bin:$HOME/.local/bin
      export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
      export PATH="$PATH:/Applications/Ghostty.app/Contents/MacOS"
      bindkey '^y' autosuggest-accept
      function fzf-or-complete() {
        if [[ "$LBUFFER" =~ '\*\*$' ]]; then
          zle fzf-completion
        else
          zle expand-or-complete
        fi
      }
      zle -N fzf-or-complete
      bindkey '^I' fzf-or-complete
      abbr -S -q tn="tmux new -s"
      abbr -S -q ta="tmux a -t"
      abbr -S -q authrestart="sudo fdesetup authrestart"
      test -e "$HOME"/.wezterm_shell_integration.zsh && source "$HOME"/.wezterm_shell_integration.zsh
      test -e /Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration && source /Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration
      function note() {
        id=$(date +%Y%m%d%H%M)
        title=$1
        if [ -z "$title" ]; then
            title="Note"
        fi
        nvim "$id"_"$title".md
      }
      function chth() {
        export CURRENT_THEME=$($GIT_DIRECTORY/dotfiles/tools/change-theme/run.sh $1)
        if [ "$CURRENT_THEME" = "light" ]; then export BAT_THEME="dayfox"; else export BAT_THEME="terafox"; fi
        if [ "$2" != "--silent" ]; then
          echo "Switched to $CURRENT_THEME theme"
        fi
      }
      # Auto-detect theme from macOS appearance on startup (lightweight, no file writes)
      if ! defaults read -g AppleInterfaceStyle &>/dev/null; then
        export CURRENT_THEME="light"
        export BAT_THEME="dayfox"
      else
        export CURRENT_THEME="dark"
        export BAT_THEME="terafox"
      fi
    '')
  ];
  profileExtra = ''
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
  '';
}
