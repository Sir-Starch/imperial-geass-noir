#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
fastfetch_dir="${config_home}/fastfetch"
config_file="${fastfetch_dir}/config.jsonc"
logo_file="${fastfetch_dir}/fastfetch.webp"
timestamp="$(date +%Y%m%d-%H%M%S)"

mkdir -p "${fastfetch_dir}"

if [[ -f "${config_file}" ]]; then
  backup="${config_file}.backup-${timestamp}"
  cp "${config_file}" "${backup}"
  echo "Backed up existing fastfetch config to ${backup}."
fi

cp "${repo_dir}/fastfetch/config.jsonc" "${config_file}"
cp "${repo_dir}/fastfetch/fastfetch.webp" "${logo_file}"

echo "Installed Imperial Geass Noir fastfetch configuration to ${fastfetch_dir}."
echo "Run 'fastfetch' to view."
