{ inputs, pkgs, ... }:
{
  home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    agent-browser
    claude-code
    copilot-cli
    opencode
    gemini-cli
  ];
}
