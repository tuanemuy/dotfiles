{ self, pkgs, inputs, username, ... }:
{
  nix = {
    optimise.automatic = true;

    settings = {
      experimental-features = "nix-command flakes";
      download-buffer-size = 524288000;
      trusted-users = [
        "root"
        username
      ];
      extra-substituters = [
        "https://cache.numtide.com"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
    overlays = [
      inputs.neovim-overlay.overlays.default
      (final: prev: {
        neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (_: {
          doCheck = false;
          doInstallCheck = false;
        });
        direnv = prev.direnv.overrideAttrs (_: {
          doCheck = false;
        });
      })
    ];
  };

  users.users.${username} = {
    shell = pkgs.zsh;
  };

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Enable Touch ID for sudo (including tmux support via pam-reattach)
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  # OrbStack kept /var/run/docker.sock pointing at its daemon via a privileged
  # helper. Colima never creates the link, and macOS clears /private/var/run on
  # boot, so this has to re-run each boot rather than live in an activation
  # script. Only host-side tools need it; compose files resolve the path inside
  # the VM.
  launchd.daemons.colima-docker-socket.serviceConfig = {
    ProgramArguments = [
      "/bin/sh"
      "-c"
      "ln -sfn /Users/${username}/.colima/default/docker.sock /var/run/docker.sock"
    ];
    RunAtLoad = true;
  };

  system = {
    configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 6;

    primaryUser = username;

    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "left";
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv"; # Column view
      };

      NSGlobalDomain = {
        # Appearance
        AppleShowAllExtensions = true;

        # Keyboard
        KeyRepeat = 2;
        InitialKeyRepeat = 15;

        # Disable auto-correct and substitutions
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };

      trackpad = {
        Clicking = true; # Tap to click
        TrackpadRightClick = true; # Two-finger secondary click
        TrackpadThreeFingerDrag = false; # Disable three-finger drag
      };
    };
  };
}
