{ pkgs }:
{
  enable = true;
  plugins = with pkgs; [
    {
      plugin = tmuxPlugins.gruvbox;
      extraConfig = "set -g @tmux-gruvbox 'dark'";
    }
    {
      plugin = tmuxPlugins.resurrect;
      extraConfig = "set -g @resurrect-strategy-nvim 'session'";
    }
    {
      plugin = tmuxPlugins.continuum;
      extraConfig = ''
        set -g @continuum-restore 'on'
        set -g @continuum-save-interval '60' # minutes
      '';
    }
  ];
  clock24 = true;
  customPaneNavigationAndResize = true;
  escapeTime = 10;
  keyMode = "vi";
  mouse = true;
  terminal = "screen-256color";
  extraConfig = ''
    set-option -g status-interval 3
    set-option -g status-position top
    set-option -ga terminal-overrides ",xterm-256color:Tc"
    bind c new-window -c '#{pane_current_path}'
  '';
}
