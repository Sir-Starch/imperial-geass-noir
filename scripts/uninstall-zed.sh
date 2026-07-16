#!/usr/bin/env bash
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
zed_theme_file="${config_home}/zed/themes/imperial-geass-noir.json"

if [[ -e "${zed_theme_file}" || -L "${zed_theme_file}" ]]; then
  rm -f -- "${zed_theme_file}"
  echo "Removed Zed theme: ${zed_theme_file}"
else
  echo "Zed theme was not installed."
fi
