#!/bin/bash

theme="light"
if [ "$CURRENT_THEME" = "light" ]; then
    theme="dark"
fi

weztermConfig="$GIT_DIRECTORY/dotfiles/config/wezterm.lua"
ghosttyConfig="$GIT_DIRECTORY/dotfiles/config/ghostty.config"

if [ "$theme" = "light" ]; then
  sed -i '' 's/color_scheme[^\S]*=.*/color_scheme = "Gruvbox light, medium (base16)"/g' $weztermConfig
  sed -i '' 's/theme[^\S]*=.*/theme = GruvboxLight/g' $ghosttyConfig
fi

if [ "$theme" = "dark" ]; then
  sed -i '' 's/color_scheme[^\S]*=.*/color_scheme = "Gruvbox dark, medium (base16)"/g' $weztermConfig
  sed -i '' 's/theme[^\S]*=.*/theme = GruvboxDark/g' $ghosttyConfig
fi

echo $theme
