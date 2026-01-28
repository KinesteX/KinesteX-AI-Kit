//
//  IStyle.swift
//  KinesteXAIKit
//
//  Created by Gurbanmyrat Ataballyyev on 21.01.2026.
//
import SwiftUI

public struct IStyle {
    let style: String?
    let themeName: String?
    let loadingStickmanColor: String?
    let loadingBackgroundColor: String?
    let loadingTextColor: String?

    public init(
        style: String? = "dark",
        themeName: String? = nil,
        loadingStickmanColor: String? = nil,
        loadingBackgroundColor: String? = nil,
        loadingTextColor: String? = nil
    ) {
        self.style = style
        self.themeName = themeName
        self.loadingStickmanColor = loadingStickmanColor
        self.loadingBackgroundColor = loadingBackgroundColor
        self.loadingTextColor = loadingTextColor
    }

    func toJson() -> [String: Any] {
        var data: [String: Any] = [:]

        if let style = style { data["style"] = style }
        if let themeName = themeName { data["themeName"] = themeName }
        if let loadingStickmanColor = loadingStickmanColor {
            data["loadingStickmanColor"] = loadingStickmanColor
        }
        if let loadingBackgroundColor = loadingBackgroundColor {
            data["loadingBackgroundColor"] = loadingBackgroundColor
        }
        if let loadingTextColor = loadingTextColor {
            data["loadingTextColor"] = loadingTextColor
        }

        return data
    }
}

extension Color {
    static func fromHex(_ hex: String, opacity: Double = 1) -> Color {
        let value = Int(hex, radix: 16) ?? 0

        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: opacity
        )
    }
}
