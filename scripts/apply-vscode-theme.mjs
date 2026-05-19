#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const themeName = "Imperial Geass Noir";
const settingsFiles = [
  `${process.env.HOME}/.config/Code/User/settings.json`,
  `${process.env.HOME}/.config/Code - OSS/User/settings.json`,
  `${process.env.HOME}/.config/VSCodium/User/settings.json`,
  `${process.env.HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json`,
  `${process.env.HOME}/.var/app/com.vscodium.codium/config/VSCodium/User/settings.json`,
  `${process.env.HOME}/.var/app/com.visualstudio.code-oss/config/Code - OSS/User/settings.json`,
];

let touched = 0;

for (const file of settingsFiles) {
  const dir = dirname(file);
  if (!existsSync(dir) && existsSync(file) === false) {
    continue;
  }

  mkdirSync(dir, { recursive: true });
  const before = existsSync(file) ? readFileSync(file, "utf8") : "{\n}\n";
  const after = setJsonProperty(before, "workbench.colorTheme", themeName);

  if (after !== before) {
    writeFileSync(file, after);
  }
  touched += 1;
  console.log(`VS Code theme set in ${file}`);
}

if (touched === 0) {
  console.log("No existing VS Code/VSCodium settings directory found; theme extension was installed but settings were not changed.");
}

function setJsonProperty(text, key, value) {
  const escapedValue = JSON.stringify(value);
  const propertyPattern = new RegExp(`("${escapeRegExp(key)}"\\s*:\\s*)"[^"]*"`);

  if (propertyPattern.test(text)) {
    return text.replace(propertyPattern, `$1${escapedValue}`);
  }

  const trimmed = text.trim();
  if (trimmed === "" || trimmed === "{}") {
    return `{\n  "${key}": ${escapedValue}\n}\n`;
  }

  const lastBrace = text.lastIndexOf("}");
  if (lastBrace === -1) {
    return `{\n  "${key}": ${escapedValue}\n}\n`;
  }

  const beforeBrace = text.slice(0, lastBrace).replace(/\s*$/, "");
  const afterBrace = text.slice(lastBrace);
  const needsComma = !beforeBrace.endsWith("{") && !beforeBrace.endsWith(",");
  return `${beforeBrace}${needsComma ? "," : ""}\n  "${key}": ${escapedValue}\n${afterBrace}`;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
