{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;

  claudeVersion = "2.1.112";
  claudeHashes = {
    x86_64-linux = "sha256-V76UBtPlyuJZVSeQv3KI3WSWZ1Qw7JPb7XajOldYDT0=";
    aarch64-linux = "sha256-EBXvV0d2fNrFg3beTsmQJT3KxJMU1U4ZdQ1VEvp0IvY=";
    x86_64-darwin = "sha256-oqf+pBrO5MiJswEy3UkKwAscuGxuJXVaIk2RscupdzQ=";
    aarch64-darwin = "sha256-sFOB84J1QBK5WYQBYAD3BiovEnpqOoQ6/Dfr19RnI0A=";
  };
  claudePlatformMap = {
    x86_64-linux = "linux-x64";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "darwin-x64";
    aarch64-darwin = "darwin-arm64";
  };

  claudeCode =
    if claudeVersion != null then
      inputs.llm-agents.packages.${system}.claude-code.overrideAttrs (_old: {
        version = claudeVersion;
        src = pkgs.fetchurl {
          url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${claudeVersion}/${claudePlatformMap.${system}}/claude";
          hash = claudeHashes.${system};
        };
      })
    else
      inputs.llm-agents.packages.${system}.claude-code;
in
{
  home.packages =
    (with inputs.llm-agents.packages.${system}; [
      agent-browser
      codex
      copilot-cli
      opencode
      pi
      gemini-cli
    ])
    ++ [ claudeCode ];
}
