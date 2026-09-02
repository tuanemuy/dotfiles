{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Unstable pairs colima 0.10.3 with lima-full 2.2.0, a combination nixpkgs
  # tests together. Scoped to colima so nothing else tracks unstable.
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.packages = [
    unstable.colima
    # Not docker-client: that is an alias for docker_28, which nixpkgs marks
    # insecure (unmaintained since November 2025).
    pkgs.docker_29
    pkgs.docker-compose
    pkgs.docker-buildx
    # Provides docker-credential-osxkeychain, which ~/.docker/config.json names
    # as credsStore. Without it every registry login fails to resolve.
    pkgs.docker-credential-helpers
    # Symlinked into /usr/local/bin by OrbStack, so uninstalling it took kubectl
    # with it.
    pkgs.kubectl
  ];

  # docker_29 ships the CLI alone, with no bundled plugins. `docker compose` and
  # `docker buildx` resolve subcommands through this directory, which OrbStack
  # used to populate.
  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/bin/docker-compose";
  home.file.".docker/cli-plugins/docker-buildx".source =
    "${pkgs.docker-buildx}/bin/docker-buildx";

  # Read when a profile is created and never written back, unlike colima.yaml,
  # which colima rewrites at runtime.
  #
  # memory: the containers across all projects measured ~1.2GB combined, and a
  # vz guest grows toward its cap without returning pages to the host, so the
  # cap stays low. `colima stop && colima start --memory 8` covers heavy builds.
  #
  # mounts: colima mounts $HOME read-only by default, which would break the
  # bind-mounted MySQL data directory.
  home.file.".colima/_templates/default.yaml".text = ''
    cpu: 4
    memory: 4
    disk: 100
    runtime: docker
    vmType: vz
    rosetta: true
    mountType: virtiofs
    mounts:
      - location: "~"
        writable: true
  '';
}
