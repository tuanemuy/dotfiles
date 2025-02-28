# https://github.com/starship/starship/issues/3418
''
  __safe_zle_keymap_select() {
    zle .reset-prompt
    zle -R
  }
  if [[ "''${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select" || \
      "''${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select-wrapped" ]]; then
    zle -N zle-keymap-select __safe_zle_keymap_select
  fi
''
