{
  description = "Home Manager configuration of hikaru";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
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
      username = "hikaru";
      hostname = "h-mbp-regain";
      homeDirectory = "/home/${username}";
      darwinHomeDirectory = "/Users/${username}";
      stableVersion = "26.05";
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
        pkgs = nixpkgs.legacyPackages."x86_64-linux";

        extraSpecialArgs = {
          inherit inputs;
          gitDirectory = "${homeDirectory}/github.com/tuanemuy";
        };
        modules = [
          ./home.nix
          (
            { lib, inputs, ... }:
            {
              nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "zsh-abbr";
              home = {
                inherit username;
                homeDirectory = lib.mkForce homeDirectory;
              };
            }
          )
        ];
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
              switch =
                if isDarwin then
                  ''
                    echo " Detected macOS: Running darwin-rebuild..."
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
              default = self.apps."x86_64-linux".switch;
            };
        };
    };
}
