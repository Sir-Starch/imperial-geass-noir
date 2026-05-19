#!/usr/bin/env node
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
const extensionRoot = join(repoRoot, "vscode/imperial-geass-noir");
const pkg = JSON.parse(readFileSync(join(extensionRoot, "package.json"), "utf8"));
const outDir = join(repoRoot, "dist");
const staging = join(outDir, "vscode-vsix");
const vsixName = `${pkg.name}-${pkg.version}.vsix`;
const vsixPath = join(outDir, vsixName);

if (!existsSync(join(extensionRoot, "package.json"))) {
  throw new Error(`Missing extension package: ${extensionRoot}`);
}

rmSync(staging, { recursive: true, force: true });
mkdirSync(join(staging, "extension"), { recursive: true });
mkdirSync(outDir, { recursive: true });

cpSync(join(extensionRoot, "package.json"), join(staging, "extension/package.json"));
cpSync(join(extensionRoot, "themes"), join(staging, "extension/themes"), { recursive: true });

writeFileSync(join(staging, "[Content_Types].xml"), `<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="json" ContentType="application/json"/>
  <Default Extension="xml" ContentType="text/xml"/>
</Types>
`);

writeFileSync(join(staging, "extension.vsixmanifest"), `<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="${escapeXml(pkg.name)}" Version="${escapeXml(pkg.version)}" Publisher="${escapeXml(pkg.publisher)}"/>
    <DisplayName>${escapeXml(pkg.displayName)}</DisplayName>
    <Description xml:space="preserve">${escapeXml(pkg.description)}</Description>
    <Tags>theme;color-theme;imperial-geass-noir</Tags>
    <Categories>Themes</Categories>
    <GalleryFlags>Public</GalleryFlags>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="${escapeXml(pkg.engines.vscode)}"/>
      <Property Id="Microsoft.VisualStudio.Code.ExtensionKind" Value="ui"/>
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code"/>
  </Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
`);

rmSync(vsixPath, { force: true });
execFileSync("zip", ["-qr", vsixPath, "."], { cwd: staging, stdio: "inherit" });
console.log(vsixPath);

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}
