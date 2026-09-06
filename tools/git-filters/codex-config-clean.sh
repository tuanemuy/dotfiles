#!/usr/bin/env bash

set -euo pipefail

awk '
  # Codex rewrites the file with its own local state: absolute paths into
  # ~/.codex and ~/.cache, and the installed app version. Keep only the
  # settings that are portable across machines.
  function flush_blank_line() {
    if (blank_lines > 0) {
      print ""
      blank_lines = 0
    }
  }

  /^notify[[:space:]]*=/ {
    next
  }

  /^\[/ {
    generated = $0 == "[tui.model_availability_nux]" \
      || $0 == "[hooks.state]" \
      || $0 ~ /^\[hooks\.state\./ \
      || $0 ~ /^\[projects\./ \
      || $0 == "[desktop]" \
      || $0 ~ /^\[marketplaces[.\]]/ \
      || $0 ~ /^\[plugins[.\]]/ \
      || $0 ~ /^\[mcp_servers[.\]]/
  }

  !generated && /^$/ {
    blank_lines++
    next
  }

  !generated {
    flush_blank_line()
    print
  }
'
