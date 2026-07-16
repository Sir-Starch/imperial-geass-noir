#!/usr/bin/env bash
set -euo pipefail

vscode_extension_name="imperial-geass-noir-theme"
vscode_extension_id="imperialgeassnoir.imperial-geass-noir"

removed=()

remove_path() {
  local path="$1"
  if [[ -e "${path}" || -L "${path}" ]]; then
    rm -rf -- "${path}"
    removed+=("${path}")
  fi
}

remove_path "${HOME}/.vscode/extensions/${vscode_extension_name}"
remove_path "${HOME}/.vscode-oss/extensions/${vscode_extension_name}"
remove_path "${HOME}/.vscodium/extensions/${vscode_extension_name}"
remove_path "${HOME}/.var/app/com.visualstudio.code/data/vscode/extensions/${vscode_extension_name}"
remove_path "${HOME}/.var/app/com.vscodium.codium/data/vscode/extensions/${vscode_extension_name}"
remove_path "${HOME}/.var/app/com.visualstudio.code-oss/data/vscode/extensions/${vscode_extension_name}"

for vscode_cli in code code-oss codium vscodium; do
  if command -v "${vscode_cli}" >/dev/null 2>&1; then
    if "${vscode_cli}" --uninstall-extension "${vscode_extension_id}" >/dev/null 2>&1; then
      removed+=("${vscode_extension_id} from ${vscode_cli}")
    fi
  fi
done

if ((${#removed[@]} > 0)); then
  printf 'Removed VS Code theme from:\n  %s\n' "${removed[@]}"
else
  echo "VS Code theme was not installed."
fi
