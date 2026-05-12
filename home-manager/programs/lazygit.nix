{ pkgs, ... }:
{
  enable = true;

  settings = {
    git.pagers = [
      {
        pager = "delta --paging=never";
      }
    ];

    gui.theme = {
      selectedLineBgColor = [ "reverse" ];
      inactiveViewSelectedLineBgColor = [ "default" ];
    };
  };
}
