#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
layout_js="${script_dir}/top-panel-layout.js"

if [[ ! -f "${layout_js}" ]]; then
  echo "Layout script not found: ${layout_js}" >&2
  exit 1
fi

dbus_cmd=""
if command -v qdbus6 >/dev/null 2>&1; then
  dbus_cmd="qdbus6"
elif command -v qdbus >/dev/null 2>&1; then
  dbus_cmd="qdbus"
else
  echo "Neither qdbus6 nor qdbus is available. Install qt6-tools/qttools or apply the layout manually." >&2
  exit 1
fi

# org.kde.PlasmaShell.evaluateScript runs JavaScript inside the live shell.
"${dbus_cmd}" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "${layout_js}")"
echo "Requested Imperial Geass Noir top panel layout through ${dbus_cmd}."
