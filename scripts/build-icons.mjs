#!/usr/bin/env node
import { cpSync, existsSync, globSync, lstatSync, mkdirSync, readFileSync, readlinkSync, readdirSync, rmSync, statSync, symlinkSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { execFileSync } from "node:child_process";

const repoRoot = process.cwd();
const sourceRoot = join(repoRoot, "kde/icons/source/Papirus-Icon-Theme-Vectorel-Folders-master");
const baseTheme = join(sourceRoot, "Papirus");
const overlayTheme = join(sourceRoot, "Papirus-Adapta-Nokto");
const outTheme = join(repoRoot, "kde/icons/ImperialGeassNoir");
const launcherCrest = join(repoRoot, "assets/holy-britannian-crest.svg");

if (!existsSync(baseTheme)) {
  throw new Error(`Missing Papirus source theme: ${relative(repoRoot, baseTheme)}`);
}
if (!existsSync(overlayTheme)) {
  throw new Error(`Missing Papirus-Adapta-Nokto overlay: ${relative(repoRoot, overlayTheme)}`);
}

rmSync(outTheme, { recursive: true, force: true });
cpSync(baseTheme, outTheme, { recursive: true, verbatimSymlinks: true });
overlayCopy(overlayTheme, outTheme);
rewriteIndexTheme();

execFileSync(process.execPath, [join(repoRoot, "scripts/recolor-icons.mjs"), outTheme], {
  stdio: "inherit",
});

normalizePanelAndSymbolicForeground();
addBluetoothOverrides();
addLauncherOverrides();

console.log(`Built ${relative(repoRoot, outTheme)} from untouched Papirus source`);

function overlayCopy(from, to, isRoot = true) {
  mkdirSync(to, { recursive: true });
  const entries = cpEntries(from);
  for (const entry of entries) {
    if (isRoot && ["index.theme", "icon-theme.cache"].includes(entry)) {
      continue;
    }
    const sourcePath = join(from, entry);
    const targetPath = join(to, entry);
    const stat = lstatSync(sourcePath);
    if (stat.isDirectory()) {
      overlayCopy(sourcePath, targetPath, false);
    } else if (stat.isSymbolicLink()) {
      const followed = statSync(sourcePath);
      if (followed.isDirectory()) {
        overlayCopy(sourcePath, targetPath, false);
      } else {
        rmSync(targetPath, { force: true });
        symlinkSync(readlinkSync(sourcePath), targetPath);
      }
    } else {
      cpSync(sourcePath, targetPath, {
        force: true,
        verbatimSymlinks: true,
      });
    }
  }
}

function cpEntries(path) {
  return readdirSync(path);
}

function rewriteIndexTheme() {
  const indexPath = join(outTheme, "index.theme");
  const before = readFileSync(indexPath, "utf8");
  const after = before
    .replace(/^Name=.*$/m, "Name=Imperial Geass Noir")
    .replace(/^Comment=.*$/m, "Comment=Papirus Vectorel based icon theme recolored for Imperial Geass Noir")
    .replace(/^Inherits=.*$/m, "Inherits=breeze-dark,hicolor");
  writeFileSync(indexPath, after);
}

function addBluetoothOverrides() {
  const panelSizes = ["16x16", "22x22", "24x24"];
  const appSizes = ["16x16", "22x22", "24x24", "32x32", "48x48", "64x64"];
  const statusSizes = ["32x32", "48x48"];

  for (const size of panelSizes) {
    const panelDir = join(outTheme, size, "panel");
    mkdirSync(panelDir, { recursive: true });
    const svg = bluetoothSvg(Number(size.split("x")[0]));
    for (const name of [
      "network-bluetooth-symbolic.svg",
      "network-bluetooth-activated-symbolic.svg",
      "network-bluetooth-inactive-symbolic.svg",
      "network-bluetooth.svg",
      "network-bluetooth-activated.svg",
      "network-bluetooth-inactive.svg",
      "network-wireless-bluetooth-symbolic.svg",
      "network-wireless-bluetooth.svg",
      "org.kde.plasma.bluetooth.svg",
    ]) {
      writeFileSync(join(panelDir, name), svg);
    }
  }

  const symbolicStatus = join(outTheme, "symbolic/status");
  mkdirSync(symbolicStatus, { recursive: true });
  for (const name of [
    "bluetooth-symbolic.svg",
    "bluetooth-active-symbolic.svg",
    "bluetooth-disabled-symbolic.svg",
    "network-bluetooth-symbolic.svg",
    "network-bluetooth-activated-symbolic.svg",
    "network-bluetooth-inactive-symbolic.svg",
  ]) {
    writeFileSync(join(symbolicStatus, name), bluetoothSvg(22));
  }

  for (const size of statusSizes) {
    const statusDir = join(outTheme, size, "status");
    mkdirSync(statusDir, { recursive: true });
    for (const name of [
      "network-bluetooth-symbolic.svg",
      "network-bluetooth-activated-symbolic.svg",
      "network-bluetooth-inactive-symbolic.svg",
      "network-bluetooth.svg",
      "network-bluetooth-activated.svg",
      "network-bluetooth-inactive.svg",
    ]) {
      writeFileSync(join(statusDir, name), bluetoothSvg(Number(size.split("x")[0])));
    }
  }

  for (const size of appSizes) {
    const appsDir = join(outTheme, size, "apps");
    mkdirSync(appsDir, { recursive: true });
    const target = "preferences-system-bluetooth.svg";
    if (!existsSync(join(appsDir, target))) {
      writeFileSync(join(appsDir, target), bluetoothSvg(Number(size.split("x")[0])));
    }
    for (const name of [
      "org.kde.plasma.bluetooth.svg",
      "preferences-system-bluetooth-symbolic.svg",
      "preferences-system-bluetooth-activated-symbolic.svg",
      "preferences-system-bluetooth-inactive-symbolic.svg",
      "preferences-system-bluetooth-battery-symbolic.svg",
    ]) {
      safeSymlink(target, join(appsDir, name));
    }
  }
}

function addLauncherOverrides() {
  const sizedDirs = ["16x16", "22x22", "24x24", "32x32", "48x48", "64x64", "96x96"];
  const appNames = [
    "org.kde.plasma.kickoff.svg",
    "org.kde.plasma.kickofflegacy.svg",
    "start-here.svg",
    "start-here-kde.svg",
    "start-here-kde-plasma.svg",
  ];
  const placeNames = [
    "start-here.svg",
    "start-here-symbolic.svg",
    "start-here-kde.svg",
    "start-here-kde-symbolic.svg",
    "start-here-kde-plasma.svg",
    "start-here-kde-plasma-symbolic.svg",
  ];
  const panelNames = [
    "org.kde.plasma.kickoff.svg",
    "start-here.svg",
    "start-here-symbolic.svg",
    "start-here-kde.svg",
    "start-here-kde-symbolic.svg",
    "start-here-kde-plasma.svg",
    "start-here-kde-plasma-symbolic.svg",
  ];

  for (const sizeName of sizedDirs) {
    const size = Number(sizeName.split("x")[0]);
    const svg = launcherSvg(size);
    for (const [subdir, names] of [
      ["apps", appNames],
      ["places", placeNames],
      ["panel", panelNames],
    ]) {
      const dir = join(outTheme, sizeName, subdir);
      mkdirSync(dir, { recursive: true });
      for (const name of names) {
        writeFileSync(join(dir, name), svg);
      }
    }
  }

  const symbolicPlaces = join(outTheme, "symbolic/places");
  mkdirSync(symbolicPlaces, { recursive: true });
  for (const name of placeNames) {
    writeFileSync(join(symbolicPlaces, name), launcherSvg(22));
  }

  const scalableApps = join(outTheme, "scalable/apps");
  mkdirSync(scalableApps, { recursive: true });
  for (const name of appNames) {
    writeFileSync(join(scalableApps, name), launcherSvg(64));
  }

  const appletDir = join(outTheme, "applets/256");
  mkdirSync(appletDir, { recursive: true });
  writeFileSync(join(appletDir, "org.kde.plasma.kickoff.svg"), launcherSvg(256));
  writeFileSync(join(appletDir, "org.kde.plasma.kickofflegacy.svg"), launcherSvg(256));
}

function safeSymlink(target, linkPath) {
  rmSync(linkPath, { force: true });
  symlinkSync(target, linkPath);
}

function normalizePanelAndSymbolicForeground() {
  const files = [
    ...globSync(join(outTheme, "**/panel/*.svg"), { nodir: true }),
    ...globSync(join(outTheme, "symbolic/**/*.svg"), { nodir: true }),
  ];

  for (const file of files) {
    const before = readFileSync(file, "utf8");
    const after = before
      .replace(/#(?:07070B|0D0B12|111018|191522|2B2238|6046A6|7B63C4|9E102B|D33A52|A98745|E8E1D2|A49AAD|6E8B6F|6F9FA8|8D4FB3|E6D7A8|C4A45A|735A2D|4A391F|7B5A2C|4E3A20)\b/gi, "#F1E8D2")
      .replace(/(ColorScheme-(?:Text|ButtonText|ViewText|WindowText|Highlight|NeutralText|PositiveText|NegativeText)\s*\{\s*color\s*:\s*)#[0-9a-fA-F]{3,8}/g, "$1#F1E8D2");

    if (after !== before) {
      writeFileSync(file, after);
    }
  }
}

function bluetoothSvg(size) {
  const stroke = Math.max(1.45, size * 0.086).toFixed(2);
  const scale = size / 22;
  const dot = Math.max(1.15, size * 0.06).toFixed(2);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <g transform="scale(${scale})" fill="none" stroke="#C4A45A" stroke-width="${stroke}" stroke-linecap="round" stroke-linejoin="round">
    <path d="M10.4 4.4 15.4 8.9 10.4 12.3Z"/>
    <path d="M10.4 4.4v14.2l5-4.4-5-1.9"/>
    <path d="M10.4 12.3 6.7 16"/>
    <path d="M10.4 12.3 6.7 8"/>
  </g>
  <circle cx="${size * 0.82}" cy="${size * 0.26}" r="${dot}" fill="#6046A6"/>
</svg>
`;
}

function launcherSvg(size) {
  return readFileSync(launcherCrest, "utf8")
    .replace(/width="[^"]+"/, `width="${size}"`)
    .replace(/height="[^"]+"/, `height="${size}"`);
}
