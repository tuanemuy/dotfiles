{ self, pkgs, inputs, username, ... }:
{
  nix = {
    optimise.automatic = true;

    settings = {
      experimental-features = "nix-command flakes";
      download-buffer-size = 524288000;
    };
  };

  nixpkgs = {
    # The platform the configuration will be used on.
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
    overlays = [
      inputs.neovim-overlay.overlays.default
      (final: prev: {
        direnv = prev.direnv.overrideAttrs (_: {
          doCheck = false;
        });
      })
    ];
  };

  users.users.${username} = {
    shell = pkgs.zsh;
  };

  # Enable Touch ID for sudo (including tmux support via pam-reattach)
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

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
