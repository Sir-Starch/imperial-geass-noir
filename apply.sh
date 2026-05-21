#!/usr/bin/env bash
set -euo pipefail

theme_slug="imperial-geass-noir"
color_name="ImperialGeassNoir"
desktop_theme="ImperialGeassNoir"
look_name="org.kde.imperialgeassnoir.desktop"
icon_theme="ImperialGeassNoir"
aurorae_theme="__aurorae__svg__ImperialGeassNoir"
aurorae_id="ImperialGeassNoir"

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
cache_home="${XDG_CACHE_HOME:-${HOME}/.cache}"
wallpaper_standard="${data_home}/wallpapers/${theme_slug}/imperial-geass-noir-gold.svg"
wallpaper_ultrawide="${data_home}/wallpapers/${theme_slug}/imperial-geass-noir-gold-ultrawide.svg"
zsh_theme_file="${config_home}/zsh/themes/imperial-geass-noir.zsh"
bash_theme_file="${config_home}/bash/themes/imperial-geass-noir.sh"
zshrc="${HOME}/.zshrc"
bashrc="${HOME}/.bashrc"
zsh_marker_begin="# >>> Imperial Geass Noir >>>"
zsh_marker_end="# <<< Imperial Geass Noir <<<"
bash_marker_begin="# >>> Imperial Geass Noir Bash >>>"
bash_marker_end="# <<< Imperial Geass Noir Bash <<<"

success=()
manual=()

can_use_live_kde=false
if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && { [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ -n "${DISPLAY:-}" ]]; }; then
  can_use_live_kde=true
fi

run_optional() {
  local label="$1"
  shift

  if "$@"; then
    success+=("${label}")
  else
    manual+=("${label}")
  fi
}

link_marked_shell_block() {
  local rc_file="$1"
  local begin="$2"
  local end="$3"
  local source_line="$4"
  local label="$5"
  local tmp_file

  mkdir -p -- "$(dirname -- "${rc_file}")"
  if [[ -f "${rc_file}" ]]; then
    if grep -Fqx "${begin}" "${rc_file}"; then
      tmp_file="$(mktemp)"
      awk -v begin="${begin}" -v end="${end}" '
        $0 == begin { skip = 1; next }
        $0 == end { skip = 0; next }
        skip != 1 { print }
      ' "${rc_file}" > "${tmp_file}"
      {
        printf '\n%s\n' "${begin}"
        printf '%s\n' "${source_line}"
        printf '%s\n' "${end}"
      } >> "${tmp_file}"
      cp "${tmp_file}" "${rc_file}"
      rm -f -- "${tmp_file}"
    else
      cp "${rc_file}" "${rc_file}.backup-$(date +%Y%m%d-%H%M%S)"
      {
        printf '\n%s\n' "${begin}"
        printf '%s\n' "${source_line}"
        printf '%s\n' "${end}"
      } >> "${rc_file}"
    fi
  else
    {
      printf '%s\n' "${begin}"
      printf '%s\n' "${source_line}"
      printf '%s\n' "${end}"
    } > "${rc_file}"
  fi

  success+=("${label}")
}

ensure_kwin_decoration_file() {
  local kwin_file="${config_home}/kwinrc"
  local tmp_file

  mkdir -p -- "$(dirname -- "${kwin_file}")"
  touch -- "${kwin_file}"
  tmp_file="$(mktemp)"

  # KConfig may omit keys from kwinrc when they match kdedefaults. Keep an
  # explicit decoration block so KWin cannot fall back to Plastik/Breeze.
  awk '
    /^\[org\.kde\.kdecoration2\]$/ { skip = 1; next }
    /^\[/ { skip = 0 }
    skip != 1 { print }
  ' "${kwin_file}" > "${tmp_file}"

  {
    printf '\n[org.kde.kdecoration2]\n'
    printf 'NoPlugin=false\n'
    printf 'library=org.kde.kwin.aurorae.v2\n'
    printf 'theme=%s\n' "${aurorae_theme}"
  } >> "${tmp_file}"

  mv -- "${tmp_file}" "${kwin_file}"
}

aurorae_available() {
  [[ -f "${data_home}/aurorae/themes/${aurorae_id}/decoration.svg" ]] || return 1
  [[ -f "${data_home}/aurorae/themes/${aurorae_id}/auroraerc" ]] || return 1
  [[ -x /usr/lib/kwin-applywindowdecoration ]] || command -v kwin-applywindowdecoration >/dev/null 2>&1 || return 1
}

apply_aurorae_decoration() {
  local apply_cmd
  local output_file

  if [[ -x /usr/lib/kwin-applywindowdecoration ]]; then
    apply_cmd="/usr/lib/kwin-applywindowdecoration"
  else
    apply_cmd="kwin-applywindowdecoration"
  fi

  output_file="$(mktemp)"
  if "${apply_cmd}" "${aurorae_theme}" >"${output_file}" 2>&1; then
    if grep -qi "already set" "${output_file}"; then
      # KWin can keep Aurorae SVG/rc cached when the same theme id is
      # reinstalled. Briefly switch away and back so script application behaves
      # like choosing the decoration manually in System Settings.
      "${apply_cmd}" "Breeze" >/dev/null 2>&1 || true
      "${apply_cmd}" "${aurorae_theme}" >/dev/null 2>&1
    fi
    rm -f -- "${output_file}"
    return 0
  fi

  rm -f -- "${output_file}"
  return 1
}

invalidate_plasma_theme_cache() {
  local cache_file
  local stamp
  local moved=false
  local had_nullglob=false

  stamp="$(date +%Y%m%d-%H%M%S)"
  if shopt -q nullglob; then
    had_nullglob=true
  fi
  shopt -s nullglob

  for cache_file in \
    "${cache_home}/plasma_theme_${desktop_theme}.kcache" \
    "${cache_home}/plasma_theme_${desktop_theme}.kcache2" \
    "${cache_home}/plasma_theme_${desktop_theme}"*.kcache \
    "${cache_home}/ksvg-elements" \
    "${cache_home}/ksvg-elements-"* \
    "${cache_home}/plasma-svgelements" \
    "${cache_home}/plasma-svgelements-"*; do
    if [[ -e "${cache_file}" ]]; then
      mv -- "${cache_file}" "${cache_file}.backup-${stamp}"
      moved=true
    fi
  done
  if [[ "${had_nullglob}" == true ]]; then
    shopt -s nullglob
  else
    shopt -u nullglob
  fi

  if [[ "${moved}" == true ]]; then
    success+=("Plasma/KSvg theme cache invalidated")
  fi
}

apply_plasma_desktop_theme() {
  command -v plasma-apply-desktoptheme >/dev/null 2>&1 || return 127

  # Plasma can answer "already set" without reloading KSvg caches. Switch away
  # briefly so updated panel/widget SVGs are parsed again in the live session.
  plasma-apply-desktoptheme org.kde.breeze >/dev/null 2>&1 \
    || plasma-apply-desktoptheme default >/dev/null 2>&1 \
    || true

  plasma-apply-desktoptheme "${desktop_theme}" >/dev/null 2>&1
}

sanitize_plasma_system_tray() {
  local plasma_file="${config_home}/plasma-org.kde.plasma.desktop-appletsrc"
  local kwrite_cmd=""
  local panel_id=""
  local tray_id=""
  local visible_items="org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.networkmanagement,org.kde.plasma.notifications,org.kde.plasma.volume"
  local hidden_items="org.kde.plasma.battery,org.kde.plasma.keyboardlayout,org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.keyboardindicator,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.printmanager,org.kde.plasma.weather,org.kde.kscreen"
  local known_items="${visible_items},${hidden_items}"

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwrite_cmd="kwriteconfig6"
  elif command -v kwriteconfig5 >/dev/null 2>&1; then
    kwrite_cmd="kwriteconfig5"
  else
    return 1
  fi

  [[ -f "${plasma_file}" ]] || return 1

  panel_id="$(awk '
    function flush() {
      if (id != "" && location == "3" && plugin == "org.kde.panel") {
        found = 1
        print id
        exit
      }
    }
    /^\[Containments\]\[[0-9]+\]$/ {
      flush()
      id = $0
      sub(/^\[Containments\]\[/, "", id)
      sub(/\]$/, "", id)
      location = ""
      plugin = ""
      next
    }
    /^\[/ {
      flush()
      id = ""
      next
    }
    id != "" && /^location=/ { location = substr($0, 10) }
    id != "" && /^plugin=/ { plugin = substr($0, 8) }
    END { if (!found) flush() }
  ' "${plasma_file}")"

  [[ -n "${panel_id}" ]] || return 1

  tray_id="$(awk -v panel="${panel_id}" '
    BEGIN {
      pattern = "^\\[Containments\\]\\[" panel "\\]\\[Applets\\]\\[[0-9]+\\]$"
      prefix = "^\\[Containments\\]\\[" panel "\\]\\[Applets\\]\\["
    }
    function flush() {
      if (id != "" && plugin == "org.kde.plasma.systemtray") {
        found = 1
        print id
        exit
      }
    }
    $0 ~ pattern {
      flush()
      id = $0
      sub(prefix, "", id)
      sub(/\]$/, "", id)
      plugin = ""
      next
    }
    /^\[/ {
      flush()
      id = ""
      next
    }
    id != "" && /^plugin=/ { plugin = substr($0, 8) }
    END { if (!found) flush() }
  ' "${plasma_file}")"

  [[ -n "${tray_id}" ]] || return 1

  "${kwrite_cmd}" --file plasma-org.kde.plasma.desktop-appletsrc \
    --group Containments --group "${panel_id}" --group Applets --group "${tray_id}" --group General \
    --key extraItems "${visible_items}" || true
  "${kwrite_cmd}" --file plasma-org.kde.plasma.desktop-appletsrc \
    --group Containments --group "${panel_id}" --group Applets --group "${tray_id}" --group General \
    --key shownItems "${visible_items}" || true
  "${kwrite_cmd}" --file plasma-org.kde.plasma.desktop-appletsrc \
    --group Containments --group "${panel_id}" --group Applets --group "${tray_id}" --group General \
    --key hiddenItems "${hidden_items}" || true
  "${kwrite_cmd}" --file plasma-org.kde.plasma.desktop-appletsrc \
    --group Containments --group "${panel_id}" --group Applets --group "${tray_id}" --group General \
    --key knownItems "${known_items}" || true

  grep -Fqx "extraItems=${visible_items}" "${plasma_file}" \
    && grep -Fqx "shownItems=${visible_items}" "${plasma_file}" \
    && grep -Fqx "hiddenItems=${hidden_items}" "${plasma_file}" \
    && grep -Fqx "knownItems=${known_items}" "${plasma_file}"
}

if [[ "${can_use_live_kde}" != true ]]; then
  manual+=("Live Plasma commands: no graphical KDE session detected")
elif command -v plasma-apply-colorscheme >/dev/null 2>&1; then
  if plasma-apply-colorscheme "${color_name}" >/dev/null 2>&1; then
    success+=("KDE color scheme")
  elif plasma-apply-colorscheme "Imperial Geass Noir" >/dev/null 2>&1; then
    success+=("KDE color scheme")
  else
    manual+=("KDE color scheme")
  fi
else
  manual+=("KDE color scheme: plasma-apply-colorscheme not found")
fi

if [[ "${can_use_live_kde}" != true ]]; then
  manual+=("Plasma desktop theme: no graphical KDE session detected")
elif command -v plasma-apply-desktoptheme >/dev/null 2>&1; then
  invalidate_plasma_theme_cache
  run_optional "Plasma desktop theme" apply_plasma_desktop_theme
else
  manual+=("Plasma desktop theme: plasma-apply-desktoptheme not found")
fi

if [[ "${can_use_live_kde}" != true ]]; then
  manual+=("Look and feel package: no graphical KDE session detected")
elif command -v lookandfeeltool >/dev/null 2>&1; then
  run_optional "Look and feel package" lookandfeeltool -a "${look_name}"
else
  manual+=("Look and feel package: lookandfeeltool not found")
fi

if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig6 --file kdeglobals --group General --key ColorScheme "${color_name}"
  kwriteconfig6 --file kdeglobals --group General --key AccentColor "84,62,138"
  kwriteconfig6 --file kdeglobals --group General --key font "IBM Plex Sans,10,-1,5,50,0,0,0,0,0"
  kwriteconfig6 --file kdeglobals --group General --key menuFont "IBM Plex Sans,10,-1,5,50,0,0,0,0,0"
  kwriteconfig6 --file kdeglobals --group General --key toolBarFont "IBM Plex Sans,10,-1,5,50,0,0,0,0,0"
  kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "IBM Plex Sans,8,-1,5,50,0,0,0,0,0"
  kwriteconfig6 --file kdeglobals --group General --key fixed "IBM Plex Mono,10,-1,5,50,0,0,0,0,0"
  kwriteconfig6 --file kdeglobals --group "Colors:Button" --key DecorationFocus "24,18,36"
  kwriteconfig6 --file kdeglobals --group "Colors:Button" --key DecorationHover "24,18,36"
  kwriteconfig6 --file kdeglobals --group "Colors:Window" --key DecorationFocus "24,18,36"
  kwriteconfig6 --file kdeglobals --group "Colors:Window" --key DecorationHover "24,18,36"
  kwriteconfig6 --file kdeglobals --group "Colors:View" --key DecorationFocus "7,7,11"
  kwriteconfig6 --file kdeglobals --group "Colors:View" --key DecorationHover "7,7,11"
  kwriteconfig6 --file kdeglobals --group "Colors:Tooltip" --key DecorationFocus "13,11,18"
  kwriteconfig6 --file kdeglobals --group "Colors:Tooltip" --key DecorationHover "13,11,18"
  kwriteconfig6 --file kdeglobals --group "Colors:Header" --key DecorationFocus "13,11,18"
  kwriteconfig6 --file kdeglobals --group "Colors:Header" --key DecorationHover "13,11,18"
  kwriteconfig6 --file kdeglobals --group "Colors:Complementary" --key DecorationFocus "7,7,11"
  kwriteconfig6 --file kdeglobals --group "Colors:Complementary" --key DecorationHover "7,7,11"
  kwriteconfig6 --file kdeglobals --group "Colors:Selection" --key DecorationFocus "96,70,166"
  kwriteconfig6 --file kdeglobals --group "Colors:Selection" --key DecorationHover "96,70,166"
  kwriteconfig6 --file kdeglobals --group WM --key activeBlend "24,18,36"
  kwriteconfig6 --file kdeglobals --group WM --key inactiveBlend "13,10,18"
  kwriteconfig6 --file kdeglobals --group WM --key activeFont "IBM Plex Sans,11,-1,5,57,0,0,0,0,0"
  kwriteconfig6 --file kdeglobals --group WM --key inactiveFont "IBM Plex Sans,11,-1,5,57,0,0,0,0,0"
  kwriteconfig6 --file kdeglobals --group Icons --key Theme "${icon_theme}"
  kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "Breeze"
  kwriteconfig6 --file kdeglobals --group KDE --key contrast 1
  kwriteconfig6 --file kdeglobals --group KDE --key frameContrast 0.2
  kwriteconfig6 --file plasmarc --group ContrastEffect --key enabled false
  kwriteconfig6 --file plasmarc --group ContrastEffect --key contrast 0.18
  kwriteconfig6 --file plasmarc --group ContrastEffect --key intensity 0.45
  kwriteconfig6 --file plasmarc --group ContrastEffect --key saturation 1.25
  kwriteconfig6 --file plasmarc --group AdaptiveTransparency --key enabled false
  kwriteconfig6 --file plasmarc --group Theme --key name "${desktop_theme}"
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae.v2"
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "${aurorae_theme}"
  kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme "${color_name}"
  kwriteconfig6 --file dolphinrc --group General --key ShowFullPath true
  kwriteconfig6 --file dolphinrc --group General --key RememberOpenedTabs false
  kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "ImperialGeassNoir.profile"
  kwriteconfig6 --file kwinrc --group kwin6_effect_tv_glitch --key Color "#556046A6"
  kwriteconfig6 --file kwinrc --group kwin6_effect_tv_glitch --key Duration 420
  kwriteconfig6 --file kwinrc --group kwin6_effect_tv_glitch --key Strength 1.2
  kwriteconfig6 --file kwinrc --group kwin6_effect_tv_glitch --key Speed 1.0
  kwriteconfig6 --file kwinrc --group Effect-kwin6_effect_tv_glitch --key Color "13,11,18"
  kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
  kwriteconfig6 --file kwinrc --group Plugins --key contrastEnabled false
  ensure_kwin_decoration_file
  kwriteconfig6 --file kdeglobals --group General --key ColorSchemeHash --delete >/dev/null 2>&1 || true
  success+=("KDE apps, Dolphin, Konsole, fonts, icons, and accent config")
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  kwriteconfig5 --file kdeglobals --group General --key ColorScheme "${color_name}"
  kwriteconfig5 --file kdeglobals --group General --key AccentColor "84,62,138"
  kwriteconfig5 --file kdeglobals --group General --key font "IBM Plex Sans,10,-1,5,50,0,0,0,0,0"
  kwriteconfig5 --file kdeglobals --group General --key menuFont "IBM Plex Sans,10,-1,5,50,0,0,0,0,0"
  kwriteconfig5 --file kdeglobals --group General --key toolBarFont "IBM Plex Sans,10,-1,5,50,0,0,0,0,0"
  kwriteconfig5 --file kdeglobals --group General --key smallestReadableFont "IBM Plex Sans,8,-1,5,50,0,0,0,0,0"
  kwriteconfig5 --file kdeglobals --group General --key fixed "IBM Plex Mono,10,-1,5,50,0,0,0,0,0"
  kwriteconfig5 --file kdeglobals --group "Colors:Button" --key DecorationFocus "24,18,36"
  kwriteconfig5 --file kdeglobals --group "Colors:Button" --key DecorationHover "24,18,36"
  kwriteconfig5 --file kdeglobals --group "Colors:Window" --key DecorationFocus "24,18,36"
  kwriteconfig5 --file kdeglobals --group "Colors:Window" --key DecorationHover "24,18,36"
  kwriteconfig5 --file kdeglobals --group "Colors:View" --key DecorationFocus "7,7,11"
  kwriteconfig5 --file kdeglobals --group "Colors:View" --key DecorationHover "7,7,11"
  kwriteconfig5 --file kdeglobals --group "Colors:Tooltip" --key DecorationFocus "13,11,18"
  kwriteconfig5 --file kdeglobals --group "Colors:Tooltip" --key DecorationHover "13,11,18"
  kwriteconfig5 --file kdeglobals --group "Colors:Header" --key DecorationFocus "13,11,18"
  kwriteconfig5 --file kdeglobals --group "Colors:Header" --key DecorationHover "13,11,18"
  kwriteconfig5 --file kdeglobals --group "Colors:Complementary" --key DecorationFocus "7,7,11"
  kwriteconfig5 --file kdeglobals --group "Colors:Complementary" --key DecorationHover "7,7,11"
  kwriteconfig5 --file kdeglobals --group "Colors:Selection" --key DecorationFocus "96,70,166"
  kwriteconfig5 --file kdeglobals --group "Colors:Selection" --key DecorationHover "96,70,166"
  kwriteconfig5 --file kdeglobals --group WM --key activeBlend "24,18,36"
  kwriteconfig5 --file kdeglobals --group WM --key inactiveBlend "13,10,18"
  kwriteconfig5 --file kdeglobals --group WM --key activeFont "IBM Plex Sans,11,-1,5,57,0,0,0,0,0"
  kwriteconfig5 --file kdeglobals --group WM --key inactiveFont "IBM Plex Sans,11,-1,5,57,0,0,0,0,0"
  kwriteconfig5 --file kdeglobals --group Icons --key Theme "${icon_theme}"
  kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle "Breeze"
  kwriteconfig5 --file kdeglobals --group KDE --key contrast 1
  kwriteconfig5 --file kdeglobals --group KDE --key frameContrast 0.2
  kwriteconfig5 --file plasmarc --group ContrastEffect --key enabled false
  kwriteconfig5 --file plasmarc --group ContrastEffect --key contrast 0.18
  kwriteconfig5 --file plasmarc --group ContrastEffect --key intensity 0.45
  kwriteconfig5 --file plasmarc --group ContrastEffect --key saturation 1.25
  kwriteconfig5 --file plasmarc --group AdaptiveTransparency --key enabled false
  kwriteconfig5 --file plasmarc --group Theme --key name "${desktop_theme}"
  kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae.v2"
  kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "${aurorae_theme}"
  kwriteconfig5 --file dolphinrc --group UiSettings --key ColorScheme "${color_name}"
  kwriteconfig5 --file konsolerc --group "Desktop Entry" --key DefaultProfile "ImperialGeassNoir.profile"
  kwriteconfig5 --file kwinrc --group kwin6_effect_tv_glitch --key Color "#556046A6"
  kwriteconfig5 --file kwinrc --group kwin6_effect_tv_glitch --key Duration 420
  kwriteconfig5 --file kwinrc --group kwin6_effect_tv_glitch --key Strength 1.2
  kwriteconfig5 --file kwinrc --group kwin6_effect_tv_glitch --key Speed 1.0
  kwriteconfig5 --file kwinrc --group Effect-kwin6_effect_tv_glitch --key Color "13,11,18"
  kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled true
  kwriteconfig5 --file kwinrc --group Plugins --key contrastEnabled false
  ensure_kwin_decoration_file
  kwriteconfig5 --file kdeglobals --group General --key ColorSchemeHash --delete >/dev/null 2>&1 || true
  success+=("KDE apps, Konsole, fonts, icons, and accent config")
else
  manual+=("KDE app/icon config: kwriteconfig6 not found")
fi

vscode_extension_id="imperialgeassnoir.imperial-geass-noir"
vscode_vsix="${repo_dir}/dist/imperial-geass-noir-1.0.1.vsix"
if command -v node >/dev/null 2>&1 && command -v zip >/dev/null 2>&1 && [[ -f "${repo_dir}/scripts/build-vscode-vsix.mjs" ]]; then
  node "${repo_dir}/scripts/build-vscode-vsix.mjs" >/dev/null 2>&1 || true
fi
if [[ -f "${vscode_vsix}" ]]; then
  vscode_registered=false
  for vscode_cli in code code-oss codium vscodium; do
    if command -v "${vscode_cli}" >/dev/null 2>&1; then
      if "${vscode_cli}" --install-extension "${vscode_vsix}" --force >/dev/null 2>&1; then
        vscode_registered=true
      fi
    fi
  done
  if [[ "${vscode_registered}" == true ]]; then
    success+=("VS Code/VSCodium extension registration")
  else
    manual+=("VS Code/VSCodium extension registration: CLI install failed")
  fi
fi

if command -v node >/dev/null 2>&1 && [[ -f "${repo_dir}/scripts/apply-vscode-theme.mjs" ]]; then
  if node "${repo_dir}/scripts/apply-vscode-theme.mjs" >/dev/null 2>&1; then
    success+=("VS Code/VSCodium color theme")
  else
    manual+=("VS Code/VSCodium color theme: settings update failed")
  fi
else
  manual+=("VS Code/VSCodium color theme: node not found")
fi

if aurorae_available; then
  if apply_aurorae_decoration; then
    success+=("Aurorae window decoration")
  else
    manual+=("Aurorae window decoration: kwin-applywindowdecoration rejected ${aurorae_theme}")
  fi
else
  manual+=("Aurorae window decoration: install aurorae/kwin tools and re-run ./install.sh")
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  if kbuildsycoca6 --noincremental >/dev/null 2>&1; then
    success+=("KDE service/icon cache refresh")
  fi
fi

dbus_cmd=""
if [[ "${can_use_live_kde}" == true ]] && command -v qdbus6 >/dev/null 2>&1; then
  dbus_cmd="qdbus6"
elif [[ "${can_use_live_kde}" == true ]] && command -v qdbus >/dev/null 2>&1; then
  dbus_cmd="qdbus"
fi

if [[ -n "${dbus_cmd}" ]]; then
  # Notify KDE clients that the icon theme changed. Some apps still need a
  # restart, but this prevents Plasma from keeping stale icon cache state.
  if "${dbus_cmd}" org.kde.KGlobalSettings /KGlobalSettings notifyChange 4 0 >/dev/null 2>&1 \
    || "${dbus_cmd}" org.kde.KGlobalSettings /KGlobalSettings org.kde.KGlobalSettings.notifyChange 4 0 >/dev/null 2>&1; then
    success+=("KDE icon theme change notification")
  else
    manual+=("Icon theme live refresh: restart Dolphin/open apps if previous icons remain")
  fi
fi

if [[ "${can_use_live_kde}" != true ]]; then
  manual+=("Top panel layout: no graphical KDE session detected")
elif [[ -x "${repo_dir}/kde/scripts/apply-plasma-layout.sh" ]]; then
  if "${repo_dir}/kde/scripts/apply-plasma-layout.sh" >/dev/null 2>&1; then
    success+=("Top panel layout")
    tray_applied=false
    for tray_delay in 1 2 3 4; do
      sleep "${tray_delay}"
      if sanitize_plasma_system_tray; then
        tray_applied=true
        break
      fi
    done

    if [[ "${tray_applied}" == true ]]; then
      success+=("System Tray desktop item set")
    else
      manual+=("System Tray desktop item set: could not rewrite applet config")
    fi
  else
    manual+=("Top panel layout: qdbus script failed or Plasma Shell is unavailable")
  fi
else
  manual+=("Top panel layout: helper script is not executable")
fi

if [[ ! -f "${wallpaper_standard}" ]]; then
  wallpaper_standard="${data_home}/wallpapers/${theme_slug}/imperial-geass-noir.svg"
fi
if [[ ! -f "${wallpaper_ultrawide}" ]]; then
  wallpaper_ultrawide="${data_home}/wallpapers/${theme_slug}/imperial-geass-noir-ultrawide.svg"
fi

if [[ -n "${dbus_cmd}" && -f "${wallpaper_standard}" && -f "${wallpaper_ultrawide}" ]]; then
  wallpaper_standard_uri="file://${wallpaper_standard}"
  wallpaper_ultrawide_uri="file://${wallpaper_ultrawide}"
  wallpaper_script="
var standardWallpaper = '${wallpaper_standard_uri}';
var ultrawideWallpaper = '${wallpaper_ultrawide_uri}';
var ultrawideRatio = 2.0;

function geometryForDesktop(desktop, index) {
  var candidates = [];

  try {
    if (desktop.screen !== undefined) {
      candidates.push(desktop.screen);
    }
  } catch (e) {}

  try {
    if (typeof desktop.screen === 'function') {
      candidates.push(desktop.screen());
    }
  } catch (e) {}

  candidates.push(index);

  for (var i = 0; i < candidates.length; ++i) {
    try {
      var geometry = screenGeometry(candidates[i]);
      if (geometry && geometry.width && geometry.height) {
        return geometry;
      }
    } catch (e) {}
  }

  try {
    if (desktop.width && desktop.height) {
      return { width: desktop.width, height: desktop.height };
    }
  } catch (e) {}

  return null;
}

var ds = desktops();
for (var i = 0; i < ds.length; ++i) {
  var desktop = ds[i];
  var geometry = geometryForDesktop(desktop, i);
  var image = standardWallpaper;

  if (geometry && geometry.height > 0 && (geometry.width / geometry.height) >= ultrawideRatio) {
    image = ultrawideWallpaper;
  }

  desktop.wallpaperPlugin = 'org.kde.image';
  desktop.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
  desktop.writeConfig('Image', image);
  desktop.writeConfig('FillMode', 2);
}
"
  if "${dbus_cmd}" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "${wallpaper_script}" >/dev/null 2>&1; then
    success+=("Gold wallpaper with monitor aspect detection")
  else
    manual+=("Wallpaper: qdbus call failed")
  fi
else
  manual+=("Wallpaper: qdbus unavailable or installed wallpaper not found")
fi

if [[ -n "${dbus_cmd}" ]]; then
  if "${dbus_cmd}" org.kde.KWin /KWin reconfigure >/dev/null 2>&1; then
    success+=("KWin decoration reload")
  else
    manual+=("KWin decoration reload: qdbus call failed")
  fi
fi

if [[ -f "${zsh_theme_file}" ]]; then
  link_marked_shell_block "${zshrc}" "${zsh_marker_begin}" "${zsh_marker_end}" "source \"${zsh_theme_file}\"" "zsh prompt linked last"
else
  manual+=("zsh prompt: installed theme file not found")
fi

if [[ -f "${bash_theme_file}" ]]; then
  link_marked_shell_block "${bashrc}" "${bash_marker_begin}" "${bash_marker_end}" "source \"${bash_theme_file}\"" "bash prompt linked last"
else
  manual+=("bash prompt: installed theme file not found")
fi

if [[ -f "${config_home}/fish/conf.d/imperial-geass-noir.fish" ]]; then
  success+=("fish prompt profile installed")
else
  manual+=("fish prompt: installed conf.d profile not found")
fi

if [[ -f "${config_home}/starship/imperial-geass-noir.toml" ]]; then
  success+=("starship profile installed")
else
  manual+=("starship profile: installed config not found")
fi

echo "Imperial Geass Noir apply results:"
if ((${#success[@]} > 0)); then
  printf '  Applied: %s\n' "${success[@]}"
fi
if ((${#manual[@]} > 0)); then
  printf '  Manual: %s\n' "${manual[@]}"
fi

echo
echo "No Plasma restart was forced. If changes do not fully appear, log out/in or restart Plasma manually."
if command -v kquitapp6 >/dev/null 2>&1 && command -v kstart6 >/dev/null 2>&1; then
  echo "Optional manual restart: kquitapp6 plasmashell && kstart6 plasmashell"
fi
