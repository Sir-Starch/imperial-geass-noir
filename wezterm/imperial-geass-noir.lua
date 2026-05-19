local wezterm = require "wezterm"

return {
  font = wezterm.font_with_fallback({
    "IBM Plex Mono",
    "JetBrainsMono Nerd Font",
    "monospace",
  }),
  font_size = 11.5,
  window_background_opacity = 0.92,
  window_padding = {
    left = 10,
    right = 10,
    top = 10,
    bottom = 10,
  },
  colors = {
    foreground = "#E8E1D2",
    background = "#07070B",
    cursor_bg = "#C4A45A",
    cursor_fg = "#07070B",
    selection_bg = "#3A1425",
    selection_fg = "#E8E1D2",
    ansi = {
      "#0D0B12",
      "#9E102B",
      "#6E8B6F",
      "#C4A45A",
      "#6046A6",
      "#8D4FB3",
      "#6F9FA8",
      "#D8D0C0",
    },
    brights = {
      "#2B2238",
      "#D33A52",
      "#8BA68A",
      "#E0C27A",
      "#7D63C4",
      "#AE70CD",
      "#8CBCC4",
      "#FFF6E5",
    },
  },
}
