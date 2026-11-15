{
  inputs,
  config,
  lib,
  pkgs,
  gitDirectory,
  ...
}:
let
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
  # Stable 25.11 has no omniwm; nixpkgs ships it on the unstable channels
  # alone. Scoped here so nothing else tracks unstable.
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.packages = [ unstable.omniwm ];

  # Stands in for aerospace's start-at-login. KeepAlive stays off so quitting
  # OmniWM from its own menu keeps it quit until the next login.
  launchd.agents.omniwm = {
    enable = true;
    config = {
      Program = "${unstable.omniwm}/Applications/OmniWM.app/Contents/MacOS/OmniWM";
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  # The directory, not settings.toml itself: OmniWM rewrites that file from its
  # Settings window with an atomic rename, which replaces a file-level symlink
  # with a regular file. Linking the directory keeps the rename inside the
  # repository, so changes made in the GUI land in git. Runtime state
  # (clipboard history, the window restore catalog) lives in
  # ~/.local/state/omniwm and never enters this directory.
  home.file.".config/omniwm".source = mkOutOfStoreSymlink "${gitDirectory}/dotfiles/config/omniwm";
}
