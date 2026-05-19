#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { globSync } from "node:fs";

const root = process.argv[2] || "kde/icons/ImperialGeassNoir";

const palette = {
  background: "#07070B",
  panel: "#0D0B12",
  surface: "#111018",
  surfaceAlt: "#191522",
  purple: "#6046A6",
  purpleSoft: "#7B63C4",
  purpleDeep: "#2B2238",
  purpleNoir: "#191522",
  crimson: "#9E102B",
  crimsonSoft: "#D33A52",
  goldWhite: "#F1E8D2",
  goldLight: "#E6D7A8",
  gold: "#C4A45A",
  goldDeep: "#A98745",
  goldBronze: "#7B5A2C",
  goldShadow: "#4E3A20",
  text: "#E8E1D2",
  muted: "#A49AAD",
  border: "#2B2238",
  green: "#6E8B6F",
  cyan: "#6F9FA8",
  magenta: "#8D4FB3",
};

const exactMap = new Map(
  Object.entries({
    "#07070b": palette.background,
    "#0d0b12": palette.panel,
    "#111018": palette.surface,
    "#191522": palette.surfaceAlt,
    "#6046a6": palette.purple,
    "#7b63c4": palette.purpleSoft,
    "#2b2238": palette.purpleDeep,
    "#191522": palette.purpleNoir,
    "#9e102b": palette.crimson,
    "#d33a52": palette.crimsonSoft,
    "#f1e8d2": palette.goldWhite,
    "#e6d7a8": palette.goldLight,
    "#c4a45a": palette.gold,
    "#a98745": palette.goldDeep,
    "#735a2d": palette.goldBronze,
    "#4a391f": palette.goldShadow,
    "#e8e1d2": palette.text,
    "#a49aad": palette.muted,
    "#2b2238": palette.border,
    "#6e8b6f": palette.green,
    "#6f9fa8": palette.cyan,
    "#8d4fb3": palette.magenta,
    "#000000": palette.purpleNoir,
    "#111111": palette.purpleNoir,
    "#222222": palette.purpleDeep,
    "#333333": palette.purpleDeep,
    "#444444": palette.purple,
    "#555555": palette.purple,
    "#666666": palette.purpleSoft,
    "#777777": palette.goldDeep,
    "#888888": palette.gold,
    "#999999": palette.goldLight,
    "#aaaaaa": palette.goldLight,
    "#bbbbbb": palette.goldLight,
    "#cccccc": palette.goldLight,
    "#dcdcdc": palette.goldLight,
    "#dddddd": palette.goldWhite,
    "#eeeeee": palette.goldWhite,
    "#ffffff": palette.goldWhite,
    "#f5f5f5": palette.goldWhite,
    "#eff0f1": palette.goldWhite,
    "#fcfcfc": palette.goldWhite,
    "#232629": palette.purpleNoir,
    "#31363b": palette.purpleDeep,
    "#4d4d4d": palette.purple,
    "#3daee9": palette.purpleSoft,
    "#1d99f3": palette.purple,
    "#5294e2": palette.purple,
    "#3689e6": palette.purple,
    "#00aaff": palette.purpleSoft,
    "#2980b9": palette.purple,
    "#3498db": palette.purpleSoft,
    "#fdbc4b": palette.goldDeep,
    "#ffc107": palette.gold,
    "#ffcc00": palette.gold,
    "#ff9800": palette.goldDeep,
    "#e67e22": palette.goldBronze,
    "#f67400": palette.goldBronze,
    "#e74c3c": palette.crimsonSoft,
    "#da4453": palette.crimsonSoft,
    "#c0392b": palette.crimson,
    "#ed1515": palette.crimson,
    "#27ae60": palette.goldDeep,
    "#2ecc71": palette.gold,
    "#2eb398": palette.purpleSoft,
    "#16a085": palette.goldDeep,
  }).map(([k, v]) => [k.toLowerCase(), v]),
);

function expand(hex) {
  if (hex.length === 3 || hex.length === 4) {
    return hex
      .split("")
      .map((c) => c + c)
      .join("");
  }
  return hex;
}

function srgbToLinear(v) {
  const c = v / 255;
  return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

function luminance(r, g, b) {
  return 0.2126 * srgbToLinear(r) + 0.7152 * srgbToLinear(g) + 0.0722 * srgbToLinear(b);
}

function rgbToHsl(r, g, b) {
  r /= 255;
  g /= 255;
  b /= 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0);
        break;
      case g:
        h = (b - r) / d + 2;
        break;
      default:
        h = (r - g) / d + 4;
    }
    h *= 60;
  }
  return { h, s, l };
}

function themedColor(raw) {
  const original = raw.toLowerCase();
  const expanded = expand(original);
  const rgb = expanded.slice(0, 6);
  const alpha = expanded.length === 8 ? expanded.slice(6) : "";
  const normalized = `#${rgb}`;

  if (exactMap.has(normalized)) {
    return withAlpha(exactMap.get(normalized), alpha);
  }

  const r = Number.parseInt(rgb.slice(0, 2), 16);
  const g = Number.parseInt(rgb.slice(2, 4), 16);
  const b = Number.parseInt(rgb.slice(4, 6), 16);
  const lum = luminance(r, g, b);
  const { h, s, l } = rgbToHsl(r, g, b);

  let next;
  if (lum < 0.025) {
    next = palette.purpleNoir;
  } else if (lum < 0.075) {
    next = palette.purpleNoir;
  } else if (s < 0.11 && lum < 0.18) {
    next = palette.purpleDeep;
  } else if (s < 0.14 && lum < 0.38) {
    next = palette.purple;
  } else if (s < 0.16 && lum < 0.62) {
    next = palette.goldDeep;
  } else if (s < 0.16 && lum < 0.82) {
    next = palette.goldLight;
  } else if (s < 0.16) {
    next = palette.goldWhite;
  } else if (h < 18 || h >= 342) {
    next = l > 0.55 ? palette.crimsonSoft : palette.crimson;
  } else if (h < 58) {
    next = l > 0.8 ? palette.goldLight : l > 0.58 ? palette.goldDeep : palette.goldBronze;
  } else if (h < 78) {
    next = l > 0.82 ? palette.goldLight : l > 0.52 ? palette.gold : palette.goldDeep;
  } else if (h < 155) {
    next = l > 0.6 ? palette.gold : palette.goldDeep;
  } else if (h < 215) {
    next = l > 0.58 ? palette.purpleSoft : palette.purple;
  } else if (h < 255) {
    next = l > 0.58 ? palette.purpleSoft : palette.purple;
  } else if (h < 315) {
    next = l > 0.58 ? palette.magenta : palette.purple;
  } else {
    next = l > 0.55 ? palette.crimsonSoft : palette.crimson;
  }

  return withAlpha(next, alpha);
}

function withAlpha(color, alpha) {
  if (!alpha || alpha === "ff") {
    return color;
  }
  return `${color}${alpha.toUpperCase()}`;
}

const files = globSync(join(root, "**/*.svg"), { nodir: true });
let changed = 0;

for (const file of files) {
  const before = readFileSync(file, "utf8");
  const after = before
    .replace(/#([0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b/g, (_m, hex) => themedColor(hex))
    .replace(/(ColorScheme-(?:Text|ButtonText|ViewText|WindowText|Highlight|NeutralText|PositiveText|NegativeText)\s*\{\s*color\s*:\s*)#[0-9a-fA-F]{3,8}/g, (_m, prefix) => `${prefix}${palette.gold}`);

  if (after !== before) {
    writeFileSync(file, after);
    changed += 1;
  }
}

console.log(`Recolored ${changed} SVG files in ${root}`);
