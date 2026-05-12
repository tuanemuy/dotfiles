{ pkgs, ... }:
{
  enable = true;
  enableZshIntegration = true;
  nix-direnv.enable = true;
  # TODO: Remove once NixOS/nixpkgs#507531 is fixed
  # fish test hangs on darwin due to broken Mach-O codesign in Nix sandbox
  package = pkgs.direnv.overrideAttrs (_: { doCheck = false; });
}
