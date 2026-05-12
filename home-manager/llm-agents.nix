{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = with inputs.llm-agents.packages.${system}; [
    agent-browser
    claude-code
    codex
    copilot-cli
    gemini-cli
    opencode
    pi
  ];
}
