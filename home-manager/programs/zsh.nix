{ pkgs }:
{
  enable = true;
  enableCompletion = true;
  autosuggestion.enable = true;
  defaultKeymap = "viins";
  shellAliases = {
    ls = "eza --icons auto";
    ll = "eza -hlmU --icons --git";
    "md-to-pdf" = "npx md-to-pdf --config-file ~/.tools/md-to-pdf/config.js";
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
  initExtraFirst = import ../workarounds/starship.nix;
  initExtra = ''
    bindkey '^y' autosuggest-accept
    test -e "$HOME"/.iterm2_shell_integration.zsh && source "$HOME"/.iterm2_shell_integration.zsh
    function note() {
      id="$(node ~/.tools/unique-id/uuidv7.js)"
      title=$1
      if [ -z "$title" ]; then
          title="Note"
      fi
      nvim "$id"_"$title".md
    }
  '';
  profileExtra = ''
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
  '';
}
