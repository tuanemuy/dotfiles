{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.6.21";
  sources = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      sha256 = "6a0a325cce5212ad8a126b3772687bbceb92ced18231b8d92d240d180f569fe2";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      sha256 = "003f7bacdcae565125bd77cb51e18224b4ca8d8f1b28d1439672a06903a26aae";
    };
    # musl builds are statically linked, so they run on non-NixOS hosts too
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      sha256 = "2399b614898ca3548c0fca9b4a2aa8b5fbdb2dd1b5736a888df34bb6e8d5b9cf";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      sha256 = "e4793a566a805a714ceb73b9f89c2d723714f2e3b28cc3f8369a29bfa178ac9d";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "rinkaku: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "rinkaku";
  inherit version;

  src = fetchurl {
    url = "https://github.com/hiro-o918/rinkaku/releases/download/v${version}/rinkaku-${source.target}.tar.gz";
    inherit (source) sha256;
  };

  installPhase = ''
    runHook preInstall
    install -Dm755 rinkaku $out/bin/rinkaku
    runHook postInstall
  '';

  meta = {
    description = "See the shape of a PR before you read it";
    homepage = "https://github.com/hiro-o918/rinkaku";
    license = lib.licenses.mit;
    mainProgram = "rinkaku";
    platforms = lib.attrNames sources;
  };
}
