{ pkgs, ... }:
{
  enable = true;
  enableGitIntegration = true;

  options = {
    navigate = true;
    line-numbers = true;
    side-by-side = true;
    keep-plus-minus-markers = true;
    width = "variable";

    file-style = "yellow bold";
    file-decoration-style = "yellow ul";

    line-numbers-left-style = "blue";
    line-numbers-right-style = "blue";
    line-numbers-minus-style = "red";
    line-numbers-plus-style = "green";
    line-numbers-zero-style = "brightblack";

    theme-gruvbox-dark = {
      minus-style = ''normal "#402120"'';
      minus-emph-style = ''red bold "#533131"'';
      minus-non-emph-style = ''normal "#402120"'';
      plus-style = ''normal "#34381b"'';
      plus-emph-style = ''green bold "#3f4a25"'';
      plus-non-emph-style = ''normal "#34381b"'';
    };

    theme-gruvbox-light = {
      minus-style = ''normal "#f2d5cf"'';
      minus-emph-style = ''red bold "#ebc6c0"'';
      minus-non-emph-style = ''normal "#f2d5cf"'';
      plus-style = ''normal "#e6eabc"'';
      plus-emph-style = ''green bold "#dfe5b4"'';
      plus-non-emph-style = ''normal "#e6eabc"'';
    };
  };
}
