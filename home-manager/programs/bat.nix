{ pkgs, ... }:
{
  enable = true;
  config = {
    theme = "belafonte-light";
  };
  themes = {
    belafonte-dark = {
      src = ../../config/bat/themes;
      file = "belafonte-dark.tmTheme";
    };
    belafonte-light = {
      src = ../../config/bat/themes;
      file = "belafonte-light.tmTheme";
    };
  };
}
