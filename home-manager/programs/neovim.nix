{ inputs, pkgs, ... }:
let
  biome = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.biome;
in
{
  enable = true;
  package = pkgs.neovim-unwrapped;
  sideloadInitLua = true;
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
