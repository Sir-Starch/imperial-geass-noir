// Imperial Geass Noir top command-bar layout for Plasma 6.
//
// This mirrors the maintainer panel layout used during development. Optional
// third-party widgets are added only when installed, so the script remains safe
// on a fresh Plasma setup.

function addWidgetSafe(panel, pluginId) {
    try {
        return panel.addWidget(pluginId)
    } catch (e) {
        return null
    }
}

function writeGroup(widget, group, values) {
    if (!widget) {
        return
    }

    try {
        widget.currentConfigGroup = group
        for (var key in values) {
            widget.writeConfig(key, values[key])
        }
    } catch (e) {}
}

function addSpacer(panel) {
    return addWidgetSafe(panel, "org.kde.plasma.panelspacer")
}

var existingPanels = panels()
for (var i = 0; i < existingPanels.length; ++i) {
    var panel = existingPanels[i]
    if (panel.location === "bottom" || panel.location === "top") {
        panel.remove()
    }
}

var topPanel = new Panel
topPanel.location = "top"
topPanel.height = 42
topPanel.hiding = "none"

try {
    topPanel.floating = true
} catch (e) {}

try {
    topPanel.opacity = "adaptive"
} catch (e) {}

var kickoff = addWidgetSafe(topPanel, "org.kde.plasma.kickoff")
writeGroup(kickoff, [], {
    "icon": "org.kde.plasma.kickoff",
    "popupHeight": 761,
    "popupWidth": 671
})

var apdatifier = addWidgetSafe(topPanel, "com.github.exequtic.apdatifier")
writeGroup(apdatifier, [], {
    "popupHeight": 289,
    "popupWidth": 432
})
writeGroup(apdatifier, ["Appearance"], {
    "sorting": false
})
writeGroup(apdatifier, ["General"], {
    "aur": true,
    "flatpak": true,
    "fwupd": true,
    "newsArch": true,
    "newsKDE": true
})
writeGroup(apdatifier, ["Miscellaneous"], {
    "configMsg": false,
    "rulesMsg": false
})
writeGroup(apdatifier, ["Upgrade"], {
    "dynamicUrl": "https://archlinux.org/mirrorlist/?country=NL",
    "terminal": "/usr/bin/kitty",
    "wrapper": "yay"
})

addWidgetSafe(topPanel, "org.kde.plasma.appmenu")
addSpacer(topPanel)
addSpacer(topPanel)

var kvitals = addWidgetSafe(topPanel, "org.kde.plasma.kvitals")
writeGroup(kvitals, [], {
    "popupHeight": 269,
    "popupWidth": 324
})
writeGroup(kvitals, ["General"], {
    "showBattery": false,
    "showPower": false,
    "compactShowBattery": false,
    "compactShowPower": false,
    "displayMode": "text",
    "layoutType": "horizontal",
    "iconSize": 13,
    "fontFamily": "IBM Plex Sans",
    "fontSize": 10,
    "fontBold": false,
    "useCustomColors": true,
    "fontColor": "#E8E1D2",
    "enableThresholdColors": true,
    "warningColor": "#C4A45A",
    "criticalColor": "#D33A52",
    "metricOrder": "cpu,ram,temp,gpu,net"
})

addSpacer(topPanel)

var tasks = addWidgetSafe(topPanel, "org.kde.plasma.icontasks")
if (!tasks) {
    tasks = addWidgetSafe(topPanel, "org.kde.plasma.taskmanager")
}
writeGroup(tasks, ["General"], {
    "launchers": "preferred://filemanager,preferred://browser,applications:steam.desktop,applications:org.telegram.desktop.desktop"
})

addSpacer(topPanel)

var music = addWidgetSafe(topPanel, "plasmusic-toolbar")
writeGroup(music, [], {
    "popupHeight": 305,
    "popupWidth": 236
})
writeGroup(music, ["ConfigDialog"], {
    "DialogHeight": 630,
    "DialogWidth": 810
})
writeGroup(music, ["General"], {
    "panelIcon": "view-media-track",
    "useAlbumCoverAsPanelIcon": false,
    "fallbackToIconWhenArtNotAvailable": true,
    "albumCoverRadius": 6,
    "maxSongWidthInPanel": 220,
    "songTextInPanel": true,
    "iconInPanel": true,
    "useCustomFont": true,
    "customFont": "IBM Plex Sans,10,-1,5,50,0,0,0,0,0",
    "desktopWidgetBg": 1,
    "colorsFromAlbumCover": false,
    "panelBackgroundRadius": 6,
    "panelIconSizeRatio": 0.78,
    "panelControlsSizeRatio": 0.78,
    "spaceBetweenControlsInPanel": true,
    "mediaProgressInPanel": true,
    "fullAlbumCoverAsBackground": false
})

addSpacer(topPanel)

var trayVisibleItems = [
    "org.kde.plasma.bluetooth",
    "org.kde.plasma.brightness",
    "org.kde.plasma.clipboard",
    "org.kde.plasma.devicenotifier",
    "org.kde.plasma.networkmanagement",
    "org.kde.plasma.notifications",
    "org.kde.plasma.volume"
].join(",")

var trayHiddenItems = [
    "org.kde.plasma.battery",
    "org.kde.plasma.keyboardlayout",
    "org.kde.kdeconnect",
    "org.kde.plasma.cameraindicator",
    "org.kde.plasma.keyboardindicator",
    "org.kde.plasma.manage-inputmethod",
    "org.kde.plasma.mediacontroller",
    "org.kde.plasma.printmanager",
    "org.kde.plasma.weather",
    "org.kde.kscreen"
].join(",")

var trayKnownItems = [
    trayVisibleItems,
    trayHiddenItems
].join(",")

var tray = addWidgetSafe(topPanel, "org.kde.plasma.systemtray")
writeGroup(tray, [], {
    "popupHeight": 432,
    "popupWidth": 432
})
writeGroup(tray, ["General"], {
    "extraItems": trayVisibleItems,
    "shownItems": trayVisibleItems,
    "knownItems": trayKnownItems,
    "hiddenItems": trayHiddenItems
})

addSpacer(topPanel)
addWidgetSafe(topPanel, "org.kde.plasma.keyboardlayout")

var clock = addWidgetSafe(topPanel, "org.kde.plasma.digitalclock")
writeGroup(clock, [], {
    "popupHeight": 451,
    "popupWidth": 560
})
writeGroup(clock, ["Appearance"], {
    "dateFormat": "shortDate",
    "showDate": true,
    "showSeconds": false
})

var weather = addWidgetSafe(topPanel, "org.kde.plasma.advanced-weather-widget")
writeGroup(weather, [], {
    "popupHeight": 751,
    "popupWidth": 800
})
writeGroup(weather, ["ConfigDialog"], {
    "DialogHeight": 630,
    "DialogWidth": 810
})
writeGroup(weather, ["General"], {
    "altitude": 12,
    "autoDetectLocation": false,
    "countryCode": "NL",
    "latitude": 51.61667,
    "locationName": "Veghel, North Brabant, The Netherlands",
    "longitude": 5.54861,
    "activeLocation": "{\"name\":\"Veghel, North Brabant, The Netherlands\",\"lat\":51.61667,\"lon\":5.54861,\"altitude\":11,\"timezone\":\"Europe/Amsterdam\",\"countryCode\":\"NL\"}",
    "panelInfoMode": "simple",
    "panelSimpleIconStyle": "symbolic",
    "panelSimpleHorizontalContent": "both",
    "panelSimpleTempShadowEnabled": false,
    "panelSimpleTempShadowIntensity": 0,
    "panelSimpleTempShadowColor": "#07070B",
    "simpleTempColor": "#E8E1D2",
    "compressedBadgeColor": "#6046A6",
    "compressedBadgeOpacity": 0.72,
    "simpleIconSizeMode": "manual",
    "simpleIconSizeManual": 30,
    "simpleFontSizeMode": "manual",
    "simpleFontSizeManual": 15,
    "panelIconTheme": "symbolic",
    "panelIconSize": 22,
    "panelIconSizeMode": "manual",
    "panelIconSizeManual": 22,
    "panelSymbolicVariant": "light",
    "panelUseSystemFont": false,
    "panelFontFamily": "IBM Plex Sans",
    "panelFontSize": 12,
    "panelFontBold": false,
    "widgetIconTheme": "symbolic",
    "conditionIconTheme": "symbolic",
    "forecastIconTheme": "symbolic",
    "tooltipIconTheme": "symbolic",
    "tooltipSymbolicVariant": "light",
    "useSystemFont": false,
    "fontFamily": "IBM Plex Sans",
    "fontSize": 12,
    "fontBold": false,
    "savedLocations": "[{\"name\":\"Veghel, North Brabant, The Netherlands\",\"lat\":51.61667,\"lon\":5.54861,\"altitude\":11,\"timezone\":\"Europe/Amsterdam\",\"countryCode\":\"NL\",\"starred\":true}]",
    "simpleIconAutoSz": 42,
    "simplePanelDim": 42,
    "timezone": "Europe/Amsterdam"
})

addWidgetSafe(topPanel, "org.kde.plasma.showdesktop")
