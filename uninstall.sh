#!/usr/bin/env bash
set -euo pipefail

theme_slug="imperial-geass-noir"
color_name="ImperialGeassNoir"
theme_name="ImperialGeassNoir"
look_name="org.kde.imperialgeassnoir.desktop"
icon_name="ImperialGeassNoir"
aurorae_name="ImperialGeassNoir"

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"

kitty_conf="${config_home}/kitty/kitty.conf"
kitty_include="include ~/.config/kitty/themes/imperial-geass-noir.conf"
zshrc="${HOME}/.zshrc"
bashrc="${HOME}/.bashrc"
zsh_marker_begin="# >>> Imperial Geass Noir >>>"
zsh_marker_end="# <<< Imperial Geass Noir <<<"
bash_marker_begin="# >>> Imperial Geass Noir Bash >>>"
bash_marker_end="# <<< Imperial Geass Noir Bash <<<"
vscode_extension_name="imperial-geass-noir-theme"
vscode_extension_id="imperialgeassnoir.imperial-geass-noir"

removed=()
skipped=()

remove_path() {
  local path="$1"
  if [[ -e "${path}" || -L "${path}" ]]; then
    rm -rf -- "${path}"
    removed+=("${path}")
  else
    skipped+=("${path}")
  fi
}

remove_path "${data_home}/color-schemes/${color_name}.colors"
remove_path "${data_home}/plasma/desktoptheme/${theme_name}"
remove_path "${data_home}/plasma/look-and-feel/${look_name}"
remove_path "${data_home}/icons/${icon_name}"
remove_path "${data_home}/aurorae/themes/${aurorae_name}"
remove_path "${config_home}/kitty/themes/imperial-geass-noir.conf"
remove_path "${config_home}/zsh/themes/imperial-geass-noir.zsh"
remove_path "${config_home}/bash/themes/imperial-geass-noir.sh"
remove_path "${config_home}/fish/conf.d/imperial-geass-noir.fish"
remove_path "${config_home}/starship/imperial-geass-noir.toml"
remove_path "${data_home}/konsole/ImperialGeassNoir.colorscheme"
remove_path "${data_home}/konsole/ImperialGeassNoir.profile"
remove_path "${config_home}/alacritty/themes/imperial-geass-noir.toml"
remove_path "${config_home}/ghostty/themes/imperial-geass-noir"
remove_path "${config_home}/wezterm/imperial-geass-noir.lua"
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
remove_path "${data_home}/wallpapers/${theme_slug}"

for wallpaper_name in \
  imperial-geass-noir.svg \
  imperial-geass-noir-ultrawide.svg \
  imperial-geass-noir-gold.svg \
  imperial-geass-noir-gold-ultrawide.svg \
  imperial-geass-noir-crimson.svg \
  imperial-geass-noir-crimson-ultrawide.svg; do
  if [[ -f "${HOME}/Pictures/Wallpapers/${wallpaper_name}" ]]; then
    rm -f -- "${HOME}/Pictures/Wallpapers/${wallpaper_name}"
    removed+=("${HOME}/Pictures/Wallpapers/${wallpaper_name}")
  fi
done

if [[ -f "${kitty_conf}" ]] && grep -Fqx "${kitty_include}" "${kitty_conf}"; then
  tmp_file="$(mktemp)"
  grep -Fvx "${kitty_include}" "${kitty_conf}" > "${tmp_file}" || true
  cp "${tmp_file}" "${kitty_conf}"
  rm -f -- "${tmp_file}"
  removed+=("Imperial Geass Noir include line from ${kitty_conf}")
fi

if [[ -f "${zshrc}" ]] && grep -Fqx "${zsh_marker_begin}" "${zshrc}"; then
  tmp_file="$(mktemp)"
  awk -v begin="${zsh_marker_begin}" -v end="${zsh_marker_end}" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "${zshrc}" > "${tmp_file}"
  cp "${tmp_file}" "${zshrc}"
  rm -f -- "${tmp_file}"
  removed+=("Imperial Geass Noir zsh block from ${zshrc}")
fi

if [[ -f "${bashrc}" ]] && grep -Fqx "${bash_marker_begin}" "${bashrc}"; then
  tmp_file="$(mktemp)"
  awk -v begin="${bash_marker_begin}" -v end="${bash_marker_end}" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "${bashrc}" > "${tmp_file}"
  cp "${tmp_file}" "${bashrc}"
  rm -f -- "${tmp_file}"
  removed+=("Imperial Geass Noir bash block from ${bashrc}")
fi

echo "Imperial Geass Noir uninstall results:"
if ((${#removed[@]} > 0)); then
  printf '  Removed: %s\n' "${removed[@]}"
fi
if ((${#skipped[@]} > 0)); then
  printf '  Not present: %s\n' "${skipped[@]}"
fi
echo "kitty.conf was not deleted."
