#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
vscode_extension_name="imperial-geass-noir-theme"
vscode_extension_id="imperialgeassnoir.imperial-geass-noir"
vscode_vsix="${repo_dir}/dist/imperial-geass-noir-1.0.1.vsix"

if command -v node >/dev/null 2>&1 && command -v zip >/dev/null 2>&1; then
  node "${repo_dir}/scripts/build-vscode-vsix.mjs" >/dev/null
fi

vscode_cli_installed=false
if [[ -f "${vscode_vsix}" ]]; then
  for vscode_cli in code code-oss codium vscodium; do
    if command -v "${vscode_cli}" >/dev/null 2>&1; then
      if "${vscode_cli}" --install-extension "${vscode_vsix}" --force >/dev/null 2>&1; then
        vscode_cli_installed=true
      fi
    fi
  done
fi

for vscode_extension_dir in \
  "${HOME}/.vscode/extensions" \
  "${HOME}/.vscode-oss/extensions" \
  "${HOME}/.vscodium/extensions" \
  "${HOME}/.var/app/com.visualstudio.code/data/vscode/extensions" \
  "${HOME}/.var/app/com.vscodium.codium/data/vscode/extensions" \
  "${HOME}/.var/app/com.visualstudio.code-oss/data/vscode/extensions"; do
  mkdir -p "${vscode_extension_dir}"
  rm -rf -- "${vscode_extension_dir:?}/${vscode_extension_name}"
  if [[ "${vscode_cli_installed}" != true ]]; then
    cp -R "${repo_dir}/vscode/imperial-geass-noir" "${vscode_extension_dir}/${vscode_extension_name}"
  fi
done

if [[ "${vscode_cli_installed}" == true ]]; then
  echo "Installed VS Code theme extension via CLI (${vscode_extension_id})."
else
  echo "Installed VS Code theme extension files; CLI registration was not available."
fi

if command -v node >/dev/null 2>&1; then
  node "${repo_dir}/scripts/apply-vscode-theme.mjs"
else
  echo "node not found; VS Code theme extension was installed, but settings.json was not updated."
fi

echo "VS Code theme setup complete."
