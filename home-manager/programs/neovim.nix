{ pkgs, ... }:
{
  enable = true;
  extraPackages = with pkgs; [
    biome
    copilot-language-server
    prettierd
    markdownlint-cli2
    nil
    nixfmt-rfc-style
    vscode-langservers-extracted
    yaml-language-server
    lua-language-server
    stylua
    typos-lsp
  ];
}
