#!/usr/bin/env bash

set -euo pipefail

awk '
  function flush_blank_lines() {
    while (blank_lines > 0) {
      print ""
      blank_lines--
    }
  }

  /^\[/ {
    generated = $0 == "[tui.model_availability_nux]" || $0 == "[hooks.state]" || $0 ~ /^\[hooks\.state\./ || $0 ~ /^\[projects\./
  }

  !generated && /^$/ {
    blank_lines++
    next
  }

  !generated {
    flush_blank_lines()
    print
  }
'
