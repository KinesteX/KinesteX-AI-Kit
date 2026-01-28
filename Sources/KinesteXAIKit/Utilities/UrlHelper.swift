//
//  UrlHelper.swift
//  KinesteXAIKit
//
//  Created by Gurbanmyrat Ataballyyev on 21.01.2026.
//
import Foundation

enum UrlHelper {

    static func buildStyleQuery(_ style: IStyle?) -> [URLQueryItem] {
        let effectiveStyle = style ?? IStyle()
        
        var items: [URLQueryItem] = []
        
        if let styleValue = effectiveStyle.style {
            items.append(URLQueryItem(name: "style", value: styleValue))
        }

        if let themeName = effectiveStyle.themeName {
            items.append(URLQueryItem(name: "themeName", value: themeName))
        }
        if let loadingStickmanColor = effectiveStyle.loadingStickmanColor {
            items.append(URLQueryItem(name: "loadingStickmanColor", value: loadingStickmanColor))
        }
        
        // Handle loadingBackgroundColor with default logic
        let finalLoadingBackgroundColor: String
        if let loadingBackgroundColor = effectiveStyle.loadingBackgroundColor {
            finalLoadingBackgroundColor = loadingBackgroundColor
        } else {
            // If loadingBackgroundColor is null, use white for "light" style
            finalLoadingBackgroundColor = effectiveStyle.style == "light" ? "FFFFFF" : "000000"
        }
        items.append(URLQueryItem(name: "loadingBackgroundColor", value: finalLoadingBackgroundColor))
        
        // Handle loadingTextColor with default logic
        let finalLoadingTextColor: String
        if let loadingTextColor = effectiveStyle.loadingTextColor {
            finalLoadingTextColor = loadingTextColor
        } else {
            // If loadingTextColor is null, use black for "light" style, white for "dark" or null
            finalLoadingTextColor = effectiveStyle.style == "light" ? "000000" : "FFFFFF"
        }
        items.append(URLQueryItem(name: "loadingTextColor", value: finalLoadingTextColor))

        return items
    }

    static func appendStyle(to url: URL, style: IStyle?) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        var queryItems = components.queryItems ?? []
        let styleQueryItems = buildStyleQuery(style)
        
        // Only append if there are style parameters to add
        if !styleQueryItems.isEmpty {
            queryItems.append(contentsOf: styleQueryItems)
            components.queryItems = queryItems
        }

        return components.url ?? url
    }
}
