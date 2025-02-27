#!/usr/bin/env bash
# This tmux statusbar config was created by tmuxline.vim
# on Fri, 24 Apr 2020

set -g status-justify "left"
set -g status "on"
set -g status-left-style "none"
set -g message-command-style "fg=#ddc7a1,bg=#665c54"
set -g status-right-style "none"
set -g pane-active-border-style "fg=#a9b665"
set -g status-style "none,bg=#3c3836"
set -g message-style "fg=#ddc7a1,bg=#665c54"
set -g pane-border-style "fg=#665c54"
set -g status-right-length "100"
set -g status-left-length "100"
setw -g window-status-activity-style "none"
setw -g window-status-separator ""
setw -g window-status-style "none,fg=#ddc7a1,bg=#3c3836"
set -g status-left "#[fg=#282828,bg=#a9b665] #S #[fg=#a9b665,bg=#3c3836,nobold,nounderscore,noitalics]"
set -g status-right "#[fg=#665c54,bg=#3c3836,nobold,nounderscore,noitalics]#[fg=#ddc7a1,bg=#665c54] %Y-%m-%d  %H:%M #[fg=#a9b665,bg=#665c54,nobold,nounderscore,noitalics]#[fg=#282828,bg=#a9b665] #h "
setw -g window-status-format "#[fg=#ddc7a1,bg=#3c3836] #I #[fg=#ddc7a1,bg=#3c3836] #W "
setw -g window-status-current-format "#[fg=#3c3836,bg=#665c54,nobold,nounderscore,noitalics]#[fg=#ddc7a1,bg=#665c54] #I #[fg=#ddc7a1,bg=#665c54] #W #[fg=#665c54,bg=#3c3836,nobold,nounderscore,noitalics]"
