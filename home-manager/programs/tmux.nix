{ pkgs, ... }:
{
  enable = true;
  plugins = with pkgs; [
    {
      plugin = tmuxPlugins.resurrect;
      extraConfig = "set -g @resurrect-strategy-nvim 'session'";
    }
    {
      plugin = tmuxPlugins.continuum;
      extraConfig = ''
        set -g @continuum-restore 'on'
        set -g @continuum-save-interval '60'
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
    set -g xterm-keys on
    set-option -g status-interval 3
    set-option -g status-position top
    set-option -ga terminal-overrides ",xterm-256color:Tc"
    bind c new-window -c '#{pane_current_path}'

    col_fg="#928374"
    col_red="#cc241d"
    col_yellow="#d79921"
    col_blue="#458588"

    set-option -gq status-style "bg=default fg=''${col_fg}"
    set-option -gq window-status-style "bg=default fg=''${col_fg}"
    set-option -gq window-status-activity-style "bg=default fg=''${col_fg}"
    set-option -gq window-status-current-style "bg=default fg=''${col_fg}"
    set-option -gq pane-active-border-style "fg=''${col_fg}"
    set-option -gq pane-border-style "fg=''${col_fg}"
    set-option -gq message-style "bg=default fg=''${col_fg}"
    set-option -gq message-command-style "bg=default, fg=''${col_fg}"
    set-option -gq display-panes-active-colour "''${col_fg}"
    set-option -gq display-panes-colour "''${col_fg}"
    set-option -gq clock-mode-colour "''${col_blue}"
    set-window-option -gq window-status-bell-style "bg=default fg=''${col_red}"
    set-option -gq status-justify left
    set-option -gq status-left-style none
    set-option -gq status-left-length 80
    set-option -gq status-right-style none
    set-option -gq status-right-length 80
    set-window-option -gq window-status-separator ""
    set-option -gq status-left "#[bg=default,fg=''${col_fg}] #S"
    set-option -gq status-right ""
    set-window-option -gq window-status-current-format "#[bg=default,fg=''${col_yellow},nobold,noitalics,nounderscore] 󰍹 "
    set-window-option -gq window-status-format "#[bg=default,fg=''${col_fg},nobold,noitalics,nounderscore] 󰍹 "
  '';
}
