{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
let
  version = "0.29.3";
  sources = {
    aarch64-darwin = {
      asset = "darwin_arm64.zip";
      sha256 = "51381cc5651e186e92d215549380ca3a626b6dd57b54e5283b47aa854a031dcb";
    };
    x86_64-darwin = {
      asset = "darwin_amd64.zip";
      sha256 = "c13cd2108a30e77d3fc1e0e328457b8f7bdf340c1e569374d80c324bbb311cdb";
    };
    aarch64-linux = {
      asset = "linux_arm64.tar.gz";
      sha256 = "d8e3574eae3c06c84472d1133951f7f41d460a8fd9fd93efd3d6d867fed5a59d";
    };
    x86_64-linux = {
      asset = "linux_amd64.tar.gz";
      sha256 = "8fc67b34e92bf61fd509ee777df8d8d53442aa3c0d908e7fccffb972aad5a9eb";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "git-wt: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "git-wt";
  inherit version;

  src = fetchurl {
    url = "https://github.com/k1LoW/git-wt/releases/download/v${version}/git-wt_v${version}_${source.asset}";
    inherit (source) sha256;
  };

  nativeBuildInputs = [ unzip ];
  # The archive holds the binary and docs at its top level, with no enclosing directory.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 git-wt $out/bin/git-wt
    runHook postInstall
  '';

  meta = {
    description = "A Git subcommand that makes git worktree simple";
    homepage = "https://github.com/k1LoW/git-wt";
    license = lib.licenses.mit;
    mainProgram = "git-wt";
    platforms = lib.attrNames sources;
  };
}
