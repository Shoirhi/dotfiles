#!/usr/bin/env swift
// Ghostty設定からmacOS Terminal.appプロファイル(.terminal)を生成し、
// Terminal.appプリファレンスに直接インポートする

import Foundation
import AppKit

// MARK: - Key-Valueファイルパーサー

func parseKeyValueFile(at path: String) -> [(key: String, value: String)] {
    guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
        fputs("Error: Cannot read \(path)\n", stderr)
        exit(1)
    }
    var result: [(key: String, value: String)] = []
    for line in content.components(separatedBy: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
        guard let eqIdx = trimmed.firstIndex(of: "=") else { continue }
        let key = trimmed[..<eqIdx].trimmingCharacters(in: .whitespaces)
        let value = trimmed[trimmed.index(after: eqIdx)...].trimmingCharacters(in: .whitespaces)
        result.append((key, value))
    }
    return result
}

func parseConfig(at path: String) -> [String: String] {
    Dictionary(
        parseKeyValueFile(at: path).map { ($0.key, $0.value) },
        uniquingKeysWith: { _, last in last }
    )
}

func parseTheme(at path: String) -> (colors: [String: String], palette: [Int: String]) {
    var colors: [String: String] = [:]
    var palette: [Int: String] = [:]
    for entry in parseKeyValueFile(at: path) {
        if entry.key == "palette" {
            guard let palEq = entry.value.firstIndex(of: "=") else { continue }
            let idx = Int(entry.value[..<palEq].trimmingCharacters(in: .whitespaces)) ?? 0
            let hex = String(entry.value[entry.value.index(after: palEq)...].trimmingCharacters(in: .whitespaces))
            palette[idx] = hex
        } else {
            colors[entry.key] = entry.value
        }
    }
    return (colors, palette)
}

// MARK: - NSColor / NSFont

func colorFromHex(_ hex: String) -> NSColor {
    let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard h.count == 6,
          let r = UInt8(h.prefix(2), radix: 16),
          let g = UInt8(h.dropFirst(2).prefix(2), radix: 16),
          let b = UInt8(h.dropFirst(4).prefix(2), radix: 16) else {
        fputs("Error: Invalid hex color: \(hex)\n", stderr)
        exit(1)
    }
    return NSColor(
        calibratedRed: CGFloat(r) / 255.0,
        green: CGFloat(g) / 255.0,
        blue: CGFloat(b) / 255.0,
        alpha: 1.0
    )
}

func archive(_ object: Any) -> Data {
    guard let data = try? NSKeyedArchiver.archivedData(
        withRootObject: object, requiringSecureCoding: false
    ) else {
        fputs("Error: Failed to archive object\n", stderr)
        exit(1)
    }
    return data
}

// MARK: - Main

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: generate-profile.swift <dotfiles-dir>\n", stderr)
    exit(1)
}

let dotfilesDir = CommandLine.arguments[1]
let fm = FileManager.default

let configPath = "\(dotfilesDir)/ghostty/config"
let config = parseConfig(at: configPath)

let themeName = config["theme"] ?? "catppuccin-frappe"
let fontName = config["font-family"] ?? "Menlo"
let fontSize = CGFloat(Double(config["font-size"] ?? "13") ?? 13.0)

let themeCandidates = [
    "\(dotfilesDir)/ghostty/themes/\(themeName)",
    NSString(string: "~/.config/ghostty/themes/\(themeName)").expandingTildeInPath,
]
guard let themePath = themeCandidates.first(where: { fm.fileExists(atPath: $0) }) else {
    fputs("Error: Theme '\(themeName)' not found\n", stderr)
    exit(1)
}

let (themeColors, palette) = parseTheme(at: themePath)

let ansiKeys = [
    "ANSIBlackColor", "ANSIRedColor", "ANSIGreenColor", "ANSIYellowColor",
    "ANSIBlueColor", "ANSIMagentaColor", "ANSICyanColor", "ANSIWhiteColor",
    "ANSIBrightBlackColor", "ANSIBrightRedColor", "ANSIBrightGreenColor",
    "ANSIBrightYellowColor", "ANSIBrightBlueColor", "ANSIBrightMagentaColor",
    "ANSIBrightCyanColor", "ANSIBrightWhiteColor",
]

let profileName = "Ghostty - \(themeName)"
var profile: [String: Any] = [
    "name": profileName,
    "type": "Window Settings",
    "ProfileCurrentVersion": 2.07,
    "columnCount": 120,
    "rowCount": 36,
    "ShowWindowSettingsNameInTitle": false,
    "UseBrightBold": true,
]

profile["BackgroundColor"] = archive(colorFromHex(themeColors["background"] ?? "303446"))

let fgHex = themeColors["foreground"] ?? "c6d0f5"
let fgColorData = archive(colorFromHex(fgHex))
profile["TextColor"] = fgColorData
profile["TextBoldColor"] = fgColorData

profile["CursorColor"] = archive(colorFromHex(themeColors["cursor-color"] ?? fgHex))
profile["CursorType"] = 0

profile["SelectionColor"] = archive(colorFromHex(themeColors["selection-background"] ?? "44495d"))

for (idx, key) in ansiKeys.enumerated() {
    if let hex = palette[idx] {
        profile[key] = archive(colorFromHex(hex))
    }
}

if let font = NSFont(name: fontName, size: fontSize) {
    profile["Font"] = archive(font)
    print("Font: \(fontName) \(Int(fontSize))pt")
} else {
    fputs("Warning: Font '\(fontName)' not found, using system monospace\n", stderr)
    profile["Font"] = archive(NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular))
}

do {
    try fm.createDirectory(atPath: "\(dotfilesDir)/terminal", withIntermediateDirectories: true)
    let plistData = try PropertyListSerialization.data(
        fromPropertyList: profile, format: .xml, options: 0
    )
    let outputPath = "\(dotfilesDir)/terminal/Ghostty-\(themeName).terminal"
    try plistData.write(to: URL(fileURLWithPath: outputPath))
    print("Generated: \(outputPath)")
} catch {
    fputs("Error: Cannot write .terminal file: \(error)\n", stderr)
    exit(1)
}

// Terminal.appのWindow Settingsに直接インポート（GUIを開かずに済む）
if let terminalDefaults = UserDefaults(suiteName: "com.apple.Terminal") {
    var windowSettings = terminalDefaults.dictionary(forKey: "Window Settings") ?? [:]
    windowSettings[profileName] = profile
    terminalDefaults.set(windowSettings, forKey: "Window Settings")
    print("Imported: \(profileName)")
} else {
    fputs("Warning: Cannot access Terminal.app preferences\n", stderr)
}
