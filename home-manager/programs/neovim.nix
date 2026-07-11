{ inputs, pkgs, ... }:
{
  enable = true;
  package = pkgs.neovim-unwrapped;
  extraPackages = with pkgs; [
    tree-sitter
    biome
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
