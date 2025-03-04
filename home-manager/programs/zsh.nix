{ pkgs, gitDirectory }:
{
  enable = true;
  enableCompletion = true;
  autosuggestion.enable = true;
  defaultKeymap = "viins";
  shellAliases = {
    ls = "eza";
    ll = "eza -lhmU --git";
    lt = "eza --tree -L";
    tmn = "tmux new -s";
    tma = "tmux a -t";
    chda = "chth dark";
    chli = "chth light";
  };
  plugins = [
    {
      name = "fast-syntax-highlighting";
      src = pkgs.fetchFromGitHub {
        owner = "zdharma-continuum";
        repo = "fast-syntax-highlighting";
        rev = "v1.55";
        sha256 = "0h7f27gz586xxw7cc0wyiv3bx0x3qih2wwh05ad85bh2h834ar8d";
      };
    }
  ];
  sessionVariables = {
    GIT_DIRECTORY = gitDirectory;
  };

  initExtraFirst = import ../workarounds/starship.nix;
  initExtra = ''
    export GIT_DIRECTORY=${gitDirectory}
    export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
    export PATH="$PATH:/Applications/Ghostty.app/Contents/MacOS"
    bindkey '^y' autosuggest-accept
    test -e "$HOME"/.iterm2_shell_integration.zsh && source "$HOME"/.iterm2_shell_integration.zsh
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
      result=$($GIT_DIRECTORY/dotfiles/tools/change-theme/run.sh $1)
      if [ "$result" = "light" ]; then
          echo "Switched to light theme"
          export CURRENT_THEME="light"
      else
          echo "Switched to dark theme"
          export CURRENT_THEME="dark"
      fi
    }
  '';
  profileExtra = ''
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
  '';
}
