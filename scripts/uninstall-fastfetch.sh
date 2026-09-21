#!/usr/bin/env bash
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
fastfetch_dir="${config_home}/fastfetch"
config_file="${fastfetch_dir}/config.jsonc"
logo_file="${fastfetch_dir}/fastfetch.webp"

removed=()
skipped=()

if [[ -f "${config_file}" ]]; then
  rm -f -- "${config_file}"
  removed+=("${config_file}")
else
  skipped+=("${config_file}")
fi

if [[ -f "${logo_file}" ]]; then
  rm -f -- "${logo_file}"
  removed+=("${logo_file}")
else
  skipped+=("${logo_file}")
fi

echo "Fastfetch theme uninstall results:"
if ((${#removed[@]} > 0)); then
  printf '  Removed: %s\n' "${removed[@]}"
fi
if ((${#skipped[@]} > 0)); then
  printf '  Not present: %s\n' "${skipped[@]}"
fi
