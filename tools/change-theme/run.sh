#!/bin/bash

theme="dark"
if [ "$1" = "light" ]; then
    theme="light"
fi

weztermConfig="$GIT_DIRECTORY/dotfiles/config/wezterm.lua"
ghosttyConfig="$GIT_DIRECTORY/dotfiles/config/ghostty.config"

if [ "$theme" = "light" ]; then
  sed -i.bak 's/color_scheme[^\S]*=.*/color_scheme = "Gruvbox light, medium (base16)"/g' $weztermConfig && rm "$weztermConfig.bak"
  sed -i.bak 's/theme[^\S]*=.*/theme = GruvboxLight/g' $ghosttyConfig && rm "$ghosttyConfig.bak"
fi

if [ "$theme" = "dark" ]; then
  sed -i.bak 's/color_scheme[^\S]*=.*/color_scheme = "Gruvbox dark, medium (base16)"/g' $weztermConfig && rm "$weztermConfig.bak"
  sed -i.bak 's/theme[^\S]*=.*/theme = GruvboxDark/g' $ghosttyConfig && rm "$ghosttyConfig.bak"
fi

echo $theme
