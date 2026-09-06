{ gitDirectory, pkgs, ... }:
{
  enable = true;
  signing.format = null;
  settings = {
    user = {
      name = "tuanemuy";
      email = "22880537+tuanemuy@users.noreply.github.com";
    };
    core = {
      editor = "nvim";
      ignorecase = false;
      quotepath = false;
    };
    init = {
      defaultBranch = "main";
    };
    merge."ours-lockfile" = {
      name = "Keep ours on conflict";
      driver = "true";
    };
    filter."codex-config" = {
      clean = "${gitDirectory}/dotfiles/tools/git-filters/codex-config-clean.sh";
      required = true;
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

    # direnv
    ".envrc"
    ".direnv"

    # Claude Code local state
    ".claude/settings.local.json"
    "CLAUDE.local.md"
    ".claude/worktrees/"
  ];
}
