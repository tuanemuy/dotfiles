{
  description = "Home Manager configuration of otabe";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    neovim-overlay = {
      url = "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-darwin,
      home-manager,
      nix-darwin,
      neovim-overlay,
      ...
    }:
    let
      username = "otabe";
      hostname = "SP-PC-0008";
      homeDirectory = "/home/${username}";
      darwinHomeDirectory = "/Users/${username}";
      stableVersion = "25.11";
      linuxPkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ inputs.neovim-overlay.overlays.default ];
      };
      stableCheckScript = ''
        CURRENT="${stableVersion}"
        YEAR=''${CURRENT%.*}
        MONTH=''${CURRENT#*.}
        if [ "$MONTH" = "05" ]; then
          NEXT="''${YEAR}.11"
        else
          NEXT="$((YEAR + 1)).05"
        fi
        if git ls-remote --heads https://github.com/NixOS/nixpkgs "nixos-''${NEXT}" 2>/dev/null | grep -q "nixos-''${NEXT}"; then
          echo ""
          echo "⚠️  nixos-''${NEXT} is now available! Consider updating stableVersion in flake.nix"
          echo ""
        fi
      '';
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = linuxPkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        extraSpecialArgs = {
          inherit inputs;
          gitDirectory = "${homeDirectory}/github.com/tuanemuy";
        };
        modules = [
          ./home.nix
          (
            { lib, inputs, ... }:
            {
              home = {
                inherit username;
                homeDirectory = lib.mkForce homeDirectory;
              };
            }
          )
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";

        specialArgs = {
          inherit self;
          inherit inputs;
          inherit username;
        };

        modules = [
          ./nix-darwin/default.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit inputs;
              gitDirectory = "${darwinHomeDirectory}/github.com/tuanemuy";
            };
            home-manager.users.${username} =
              { lib, inputs, ... }:
              {
                imports = [ ./home.nix ];
                home = {
                  inherit username;
                  homeDirectory = lib.mkForce darwinHomeDirectory;
                };
              };

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };

      apps =
        let
          mkApp = system: name: script: {
            type = "app";
            program = "${(nixpkgs.legacyPackages.${system}.writeShellScriptBin name script)}/bin/${name}";
          };

          genScripts =
            system:
            let
              isDarwin = (builtins.match ".*-darwin" system) != null;
              flakePath =
                if isDarwin then
                  "${darwinHomeDirectory}/.config/home-manager"
                else
                  "${homeDirectory}/.config/home-manager";
              cacheCheck =
                if isDarwin then
                  ''
                    echo "🔍 Checking binary cache availability..."
                    DRY_RUN_OUTPUT=$(darwin-rebuild build --dry-run --flake ${flakePath}#${hostname} 2>&1) || true

                    # Lines containing .drv paths = derivations that must be built from source
                    BUILD_DRVS=$(echo "$DRY_RUN_OUTPUT" | grep '/nix/store/.*\.drv' || true)
                    BUILD_COUNT=$(echo "$BUILD_DRVS" | grep -c '/nix/store/' || true)

                    # Lines with store paths but no .drv = fetched from cache
                    FETCH_PATHS=$(echo "$DRY_RUN_OUTPUT" | grep '/nix/store/' | grep -v '\.drv' || true)
                    FETCH_COUNT=$(echo "$FETCH_PATHS" | grep -c '/nix/store/' || true)

                    if [ "$BUILD_COUNT" -gt 0 ]; then
                      echo ""
                      echo "⚠️  $BUILD_COUNT derivation(s) need to be built from source (not cached):"
                      echo "$BUILD_DRVS" | sed 's|.*/nix/store/[a-z0-9]*-||; s|\.drv$||' | head -20
                      if [ "$BUILD_COUNT" -gt 20 ]; then
                        echo "  ... and $((BUILD_COUNT - 20)) more"
                      fi
                      echo "($FETCH_COUNT path(s) will be fetched from cache)"
                      echo ""
                      echo "This may take a while and could fail in the Nix sandbox."
                      echo "Tip: Try again later when Hydra has finished building caches."
                      echo ""
                      printf "Proceed anyway? [y/N] "
                      read -r REPLY
                      if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
                        echo "Aborted."
                        exit 0
                      fi
                    else
                      echo "✅ All derivations are cached. Proceeding with switch."
                    fi
                  ''
                else
                  "";
              switch =
                if isDarwin then
                  ''
                    echo "🍎 Detected macOS: Running darwin-rebuild..."
                    ${cacheCheck}
                    sudo darwin-rebuild switch --flake ${flakePath}#${hostname}
                    ${stableCheckScript}
                  ''
                else
                  ''
                    echo "🐧 Detected Linux: Running home-manager..."
                    home-manager switch --flake ${flakePath}#${username}
                    ${stableCheckScript}
                  '';
              update = ''
                echo "🔄 Updating flake.lock..."
                nix flake update --flake ${flakePath}
                echo "✅ Flake lock file updated."
              '';
            in
            {
              switch = switch;
              update = update;
              up = ''
                ${update}
                ${switch}
              '';
              clean =
                if isDarwin then
                  ''
                    echo "🧹 Cleaning up old generations..."
                    sudo nix-collect-garbage -d
                    echo "✨ Optimizing nix store..."
                    nix-store --optimise
                    echo "✅ Done! Your nix store is now squeaky clean."
                  ''
                else
                  ''
                    echo "🧹 Cleaning up old generations..."
                    nix-collect-garbage -d
                    echo "✨ Optimizing nix store..."
                    nix-store --optimise
                    echo "✅ Done! Your nix store is now squeaky clean."
                  '';
            };
        in
        {
          "aarch64-darwin" =
            let
              s = genScripts "aarch64-darwin";
            in
            {
              switch = mkApp "aarch64-darwin" "switch" s.switch;
              update = mkApp "aarch64-darwin" "update" s.update;
              up = mkApp "aarch64-darwin" "up-sw" s.up;
              clean = mkApp "aarch64-darwin" "clean" s.clean;
              default = self.apps."aarch64-darwin".switch;
            };

          "x86_64-linux" =
            let
              s = genScripts "x86_64-linux";
            in
            {
              switch = mkApp "x86_64-linux" "switch" s.switch;
              update = mkApp "x86_64-linux" "update" s.update;
              up = mkApp "x86_64-linux" "up-sw" s.up;
              clean = mkApp "x86_64-linux" "clean" s.clean;
              default = self.apps."x86_64-linux".switch;
            };
        };
    };
}
