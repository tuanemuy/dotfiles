{ inputs, pkgs, ... }:
{
  enable = true;
  package = pkgs.neovim-unwrapped;
  sideloadInitLua = true;
  # No plugin uses the Python 3 or Ruby provider.
  withPython3 = false;
  withRuby = false;
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
