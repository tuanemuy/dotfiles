{ inputs, pkgs, ... }:
{
  home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    claude-code
    copilot-cli
    opencode
    gemini-cli
  ];
}
