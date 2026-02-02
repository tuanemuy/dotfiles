{ inputs, pkgs, ... }:
{
  enable = true;
  package = inputs.neovim-overlay.packages.${pkgs.system}.default;
  extraPackages = with pkgs; [
    biome
    prettierd
    markdownlint-cli2
    nil
    nixfmt-rfc-style
    vscode-langservers-extracted
    yaml-language-server
    lua-language-server
    stylua
  ];
}
