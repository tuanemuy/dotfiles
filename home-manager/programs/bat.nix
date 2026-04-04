{ pkgs, ... }:
{
  enable = true;
  config = {
    theme = "dayfox";
  };
  themes = {
    dayfox = {
      src = ../../config/bat/themes;
      file = "dayfox.tmTheme";
    };
    terafox = {
      src = ../../config/bat/themes;
      file = "terafox.tmTheme";
    };
  };
}
