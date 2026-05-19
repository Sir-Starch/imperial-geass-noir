#!/usr/bin/env bash
set -euo pipefail

theme_slug="imperial-geass-noir"
color_name="ImperialGeassNoir"
theme_name="ImperialGeassNoir"
look_name="org.kde.imperialgeassnoir.desktop"
icon_name="ImperialGeassNoir"
aurorae_name="ImperialGeassNoir"

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"

color_dir="${data_home}/color-schemes"
desktoptheme_dir="${data_home}/plasma/desktoptheme"
lookandfeel_dir="${data_home}/plasma/look-and-feel"
kitty_dir="${config_home}/kitty"
kitty_theme_dir="${kitty_dir}/themes"
zsh_theme_dir="${config_home}/zsh/themes"
bash_theme_dir="${config_home}/bash/themes"
fish_conf_dir="${config_home}/fish/conf.d"
starship_dir="${config_home}/starship"
konsole_dir="${data_home}/konsole"
alacritty_theme_dir="${config_home}/alacritty/themes"
ghostty_theme_dir="${config_home}/ghostty/themes"
wezterm_theme_dir="${config_home}/wezterm"
vscode_extension_name="imperial-geass-noir-theme"
vscode_extension_id="imperialgeassnoir.imperial-geass-noir"
vscode_vsix="${repo_dir}/dist/imperial-geass-noir-1.0.0.vsix"
icon_dir="${data_home}/icons"
aurorae_dir="${data_home}/aurorae/themes"
wallpaper_dir="${data_home}/wallpapers/${theme_slug}"
picture_wallpaper_dir="${HOME}/Pictures/Wallpapers"

kitty_conf="${kitty_dir}/kitty.conf"
kitty_include="include ~/.config/kitty/themes/imperial-geass-noir.conf"

timestamp="$(date +%Y%m%d-%H%M%S)"

mkdir -p \
  "${color_dir}" \
  "${desktoptheme_dir}" \
  "${lookandfeel_dir}" \
  "${icon_dir}" \
  "${aurorae_dir}" \
  "${kitty_theme_dir}" \
  "${kitty_dir}" \
  "${zsh_theme_dir}" \
  "${bash_theme_dir}" \
  "${fish_conf_dir}" \
  "${starship_dir}" \
  "${konsole_dir}" \
  "${alacritty_theme_dir}" \
  "${ghostty_theme_dir}" \
  "${wezterm_theme_dir}" \
  "${wallpaper_dir}" \
  "${picture_wallpaper_dir}"

rm -rf -- \
  "${desktoptheme_dir:?}/${theme_name}" \
  "${lookandfeel_dir:?}/${look_name}" \
  "${icon_dir:?}/${icon_name}" \
  "${aurorae_dir:?}/${aurorae_name}"

cp "${repo_dir}/kde/color-schemes/${color_name}.colors" "${color_dir}/"
cp -R "${repo_dir}/kde/plasma/desktoptheme/${theme_name}" "${desktoptheme_dir}/"
cp -R "${repo_dir}/kde/plasma/look-and-feel/${look_name}" "${lookandfeel_dir}/"
cp -R "${repo_dir}/kde/icons/${icon_name}" "${icon_dir}/"
if command -v kpackagetool6 >/dev/null 2>&1; then
  kpackagetool6 --type KWin/Aurorae --upgrade "${repo_dir}/kde/aurorae/themes/${aurorae_name}" >/dev/null 2>&1 \
    || kpackagetool6 --type KWin/Aurorae --install "${repo_dir}/kde/aurorae/themes/${aurorae_name}" >/dev/null 2>&1 \
    || cp -R "${repo_dir}/kde/aurorae/themes/${aurorae_name}" "${aurorae_dir}/"
else
  cp -R "${repo_dir}/kde/aurorae/themes/${aurorae_name}" "${aurorae_dir}/"
fi
cp "${repo_dir}/kitty/imperial-geass-noir.conf" "${kitty_theme_dir}/"
cp "${repo_dir}/zsh/imperial-geass-noir.zsh" "${zsh_theme_dir}/"
cp "${repo_dir}/bash/imperial-geass-noir.sh" "${bash_theme_dir}/"
cp "${repo_dir}/fish/conf.d/imperial-geass-noir.fish" "${fish_conf_dir}/"
cp "${repo_dir}/starship/imperial-geass-noir.toml" "${starship_dir}/"
cp "${repo_dir}/konsole/ImperialGeassNoir.colorscheme" "${konsole_dir}/"
cp "${repo_dir}/konsole/ImperialGeassNoir.profile" "${konsole_dir}/"
cp "${repo_dir}/alacritty/imperial-geass-noir.toml" "${alacritty_theme_dir}/"
cp "${repo_dir}/ghostty/imperial-geass-noir" "${ghostty_theme_dir}/"
cp "${repo_dir}/wezterm/imperial-geass-noir.lua" "${wezterm_theme_dir}/"
cp "${repo_dir}/wallpapers/"*.svg "${wallpaper_dir}/"
cp "${repo_dir}/wallpapers/"*.svg "${picture_wallpaper_dir}/"

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

if [[ -f "${kitty_conf}" ]]; then
  if grep -Fqx "${kitty_include}" "${kitty_conf}"; then
    echo "kitty.conf already includes Imperial Geass Noir."
  else
    backup="${kitty_conf}.backup-${timestamp}"
    cp "${kitty_conf}" "${backup}"
    {
      printf '\n# Imperial Geass Noir theme\n'
      printf '%s\n' "${kitty_include}"
    } >> "${kitty_conf}"
    echo "Backed up existing kitty.conf to ${backup} and added theme include."
  fi
else
  cp "${repo_dir}/kitty/kitty.conf" "${kitty_conf}"
  echo "Installed new kitty.conf."
fi

if command -v node >/dev/null 2>&1; then
  node "${repo_dir}/scripts/apply-vscode-theme.mjs"
else
  echo "node not found; VS Code theme extension was installed, but settings.json was not updated."
fi

echo
echo "Installed Imperial Geass Noir user-local files."
echo "Next steps:"
echo "  1. Run ./apply.sh to apply available KDE settings."
echo "  2. If Plasma cannot apply the panel automatically, use README manual steps."
echo "  3. Restart open KDE apps if fonts/icons do not refresh immediately."
echo "  4. Open a new terminal session for shell and terminal profile changes."
