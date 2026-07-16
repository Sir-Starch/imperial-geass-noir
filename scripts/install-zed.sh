#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
zed_theme_dir="${config_home}/zed/themes"
theme_file="imperial-geass-noir.json"

mkdir -p "${zed_theme_dir}"
cp "${repo_dir}/zed/${theme_file}" "${zed_theme_dir}/"

echo "Installed Zed theme to ${zed_theme_dir}/${theme_file}."
echo "To apply, open Zed, press CMD+K CMD+T (or CTRL+K CTRL+T) and select 'Imperial Geass Noir'."
