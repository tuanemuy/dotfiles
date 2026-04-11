#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

theme_name="${DARK_THEME}"
if [ "$1" = "light" ]; then
    theme_name="${LIGHT_THEME}"
elif [ "$1" = "auto" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        if ! defaults read -g AppleInterfaceStyle &>/dev/null; then
            theme_name="${LIGHT_THEME}"
        fi
    fi
elif [ -n "$1" ]; then
    theme_name="$1"
fi

source "$SCRIPT_DIR/themes/${theme_name}.sh"

weztermConfig="$GIT_DIRECTORY/dotfiles/config/wezterm.lua"
ghosttyConfig="$GIT_DIRECTORY/dotfiles/config/ghostty.config"
starshipConfig="$GIT_DIRECTORY/dotfiles/config/starship.toml"
tmuxDir="$GIT_DIRECTORY/dotfiles/config/tmux"

# WezTerm
sed -i.bak "s/color_scheme[^\S]*=.*/color_scheme = \"${WEZTERM_COLOR_SCHEME}\"/" "$weztermConfig" && rm -f "$weztermConfig.bak"

# Ghostty
sed -i.bak "s/theme[^\S]*=.*/theme = ${GHOSTTY_THEME}/" "$ghosttyConfig" && rm -f "$ghosttyConfig.bak"

# Starship - switch active palette
sed -i.bak "s/^palette = .*/palette = '${PALETTE_NAME}'/" "$starshipConfig" && rm -f "$starshipConfig.bak"

# Starship - regenerate palette definitions from theme files
sed -i.bak '/^# --- THEME PALETTES ---$/,$d' "$starshipConfig" && rm -f "$starshipConfig.bak"
{
    echo "# --- THEME PALETTES ---"
    for theme_file in "$SCRIPT_DIR"/themes/*.sh; do
        (
            source "$theme_file"
            cat <<PALETTE

[palettes.${PALETTE_NAME}]
color_fg0 = '${COLOR_FG0}'
color_bg1 = '${COLOR_BG1}'
color_bg3 = '${COLOR_BG3}'
color_blue = '${COLOR_BLUE}'
color_aqua = '${COLOR_AQUA}'
color_green = '${COLOR_GREEN}'
color_orange = '${COLOR_ORANGE}'
color_purple = '${COLOR_PURPLE}'
color_red = '${COLOR_RED}'
color_yellow = '${COLOR_YELLOW}'
PALETTE
        )
    done
} >> "$starshipConfig"

# Tmux - generate theme conf
cat > "$tmuxDir/theme.conf" <<TMUX
set-option -gq status-style "bg=default fg=${TMUX_FG}"
set-option -gq window-status-style "bg=default fg=${TMUX_FG}"
set-option -gq window-status-activity-style "bg=default fg=${TMUX_FG}"
set-option -gq window-status-current-style "bg=default fg=${TMUX_FG}"
set-option -gq pane-active-border-style "fg=${TMUX_FG}"
set-option -gq pane-border-style "fg=${TMUX_FG}"
set-option -gq message-style "bg=default fg=${TMUX_FG}"
set-option -gq message-command-style "bg=default fg=${TMUX_FG}"
set-option -gq display-panes-active-colour "${TMUX_FG}"
set-option -gq display-panes-colour "${TMUX_FG}"
set-option -gq clock-mode-colour "${COLOR_BLUE}"
set-window-option -gq window-status-bell-style "bg=default fg=${COLOR_RED}"
set-option -gq status-left "#[bg=default,fg=${TMUX_FG}] #S"
set-window-option -gq window-status-current-format "#[bg=default,fg=${COLOR_YELLOW},nobold,noitalics,nounderscore] 󰍹 "
set-window-option -gq window-status-format "#[bg=default,fg=${TMUX_FG},nobold,noitalics,nounderscore] 󰍹 "
TMUX

# Apply to all tmux sessions (works both inside and outside tmux)
tmux source-file "$tmuxDir/theme.conf" 2>/dev/null || true

echo "$BACKGROUND"
