{ inputs, pkgs, ... }:
{
  enable = true;
  package = inputs.neovim-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
  extraPackages = with pkgs; [
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
