{ inputs, pkgs, ... }:
let
  biome = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.biome;
in
{
  enable = true;
  package = pkgs.neovim-unwrapped;
  sideloadInitLua = true;
  # No plugin uses the Python 3 or Ruby provider.
  withPython3 = false;
  withRuby = false;
  extraWrapperArgs = [ "--prefix" "PATH" ":" "${biome}/bin" ];
  extraPackages = with pkgs; [
    tree-sitter
    prettierd
    markdownlint-cli2
    nil
    nixfmt
    vscode-langservers-extracted
    yaml-language-server
    lua-language-server
    stylua
    typos-lsp
  ];
}
