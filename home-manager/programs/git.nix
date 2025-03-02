{ pkgs, ... }:
{
  enable = true;
  userName = "tuanemuy";
  userEmail = "22880537+tuanemuy@users.noreply.github.com";
  extraConfig = {
    core = {
      editor = "vim";
      ignorecase = false;
      quotepath = false;
    };
    init = {
      defaultBranch = "main";
    };
  };
  ignores = [
    # General
    ".DS_Store"
    ".AppleDouble"
    ".LSOverride"

    # Icon must end with two \r
    "Icon"

    # Thumbnails
    "._*"

    # Files that might appear in the root of a volume
    ".DocumentRevisions-V100"
    ".fseventsd"
    ".Spotlight-V100"
    ".TemporaryItems"
    ".Trashes"
    ".VolumeIcon.icns"
    ".com.apple.timemachine.donotpresent"

    # Directories potentially created on remote AFP share
    ".AppleDB"
    ".AppleDesktop"
    "Network Trash Folder"
    "Temporary Items"
    ".apdisk"
  ];
}
