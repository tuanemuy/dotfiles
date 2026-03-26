{ pkgs, gitDirectory }:
{
  enable = true;
  enableCompletion = true;
  autosuggestion.enable = true;
  defaultKeymap = "viins";
  shellAliases = {
    ls = "eza --icons";
    ll = "eza -lhmU --icons --git";
    lt = "eza --icons --tree -L";
    dark = "chth dark";
    light = "chth light";
  } // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
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
      export CURRENT_THEME="light"
      export GIT_DIRECTORY=${gitDirectory}
      export PATH=$PATH:$(npm prefix --location=global)/bin:$HOME/.local/bin
      bindkey '^y' autosuggest-accept
      abbr -S -q tn="tmux new -s"
      abbr -S -q ta="tmux a -t"
      function note() {
        id=$(date +%Y%m%d%H%M)
        title=$1
        if [ -z "$title" ]; then
            title="Note"
        fi
        nvim "$id"_"$title".md
      }
      function chth() {
        result=$($GIT_DIRECTORY/dotfiles/tools/change-theme/run.sh $1)
        if [ "$result" = "light" ]; then
            echo "Switched to light theme"
            export CURRENT_THEME="light"
            export BAT_THEME="gruvbox-light"
        else
            echo "Switched to dark theme"
            export CURRENT_THEME="dark"
            export BAT_THEME="gruvbox-dark"
        fi
      }
    '')
  ];
  profileExtra = ''
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
  '';
}
