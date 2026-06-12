//
//  Color+Extensions.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 30/05/21.
//

import SwiftUI

///These shims predate `Color(uiColor:)` and are kept only for source
///compatibility. They are deprecated and will be removed in a future release.
public extension Color {

    @available(*, deprecated, message: "Use Color(uiColor: .label) instead; this shim will be removed in a future release.")
    static var label: Color {
        return Color(uiColor: .label)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .secondaryLabel) instead; this shim will be removed in a future release.")
    static var secondaryLabel: Color {
        return Color(uiColor: .secondaryLabel)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .tertiaryLabel) instead; this shim will be removed in a future release.")
    static var tertiaryLabel: Color {
        return Color(uiColor: .tertiaryLabel)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .quaternaryLabel) instead; this shim will be removed in a future release.")
    static var quaternaryLabel: Color {
        return Color(uiColor: .quaternaryLabel)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemFill) instead; this shim will be removed in a future release.")
    static var systemFill: Color {
        return Color(uiColor: .systemFill)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .secondarySystemFill) instead; this shim will be removed in a future release.")
    static var secondarySystemFill: Color {
        return Color(uiColor: .secondarySystemFill)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .tertiarySystemFill) instead; this shim will be removed in a future release.")
    static var tertiarySystemFill: Color {
        return Color(uiColor: .tertiarySystemFill)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .quaternarySystemFill) instead; this shim will be removed in a future release.")
    static var quaternarySystemFill: Color {
        return Color(uiColor: .quaternarySystemFill)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemBackground) instead; this shim will be removed in a future release.")
    static var systemBackground: Color {
        return Color(uiColor: .systemBackground)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .secondarySystemBackground) instead; this shim will be removed in a future release.")
    static var secondarySystemBackground: Color {
        return Color(uiColor: .secondarySystemBackground)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .tertiarySystemBackground) instead; this shim will be removed in a future release.")
    static var tertiarySystemBackground: Color {
        return Color(uiColor: .tertiarySystemBackground)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemGroupedBackground) instead; this shim will be removed in a future release.")
    static var systemGroupedBackground: Color {
        return Color(uiColor: .systemGroupedBackground)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .secondarySystemGroupedBackground) instead; this shim will be removed in a future release.")
    static var secondarySystemGroupedBackground: Color {
        return Color(uiColor: .secondarySystemGroupedBackground)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .tertiarySystemGroupedBackground) instead; this shim will be removed in a future release.")
    static var tertiarySystemGroupedBackground: Color {
        return Color(uiColor: .tertiarySystemGroupedBackground)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemRed) instead; this shim will be removed in a future release.")
    static var systemRed: Color {
        return Color(uiColor: .systemRed)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemBlue) instead; this shim will be removed in a future release.")
    static var systemBlue: Color {
        return Color(uiColor: .systemBlue)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemPink) instead; this shim will be removed in a future release.")
    static var systemPink: Color {
        return Color(uiColor: .systemPink)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemTeal) instead; this shim will be removed in a future release.")
    static var systemTeal: Color {
        return Color(uiColor: .systemTeal)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemGreen) instead; this shim will be removed in a future release.")
    static var systemGreen: Color {
        return Color(uiColor: .systemGreen)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemIndigo) instead; this shim will be removed in a future release.")
    static var systemIndigo: Color {
        return Color(uiColor: .systemIndigo)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemOrange) instead; this shim will be removed in a future release.")
    static var systemOrange: Color {
        return Color(uiColor: .systemOrange)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemPurple) instead; this shim will be removed in a future release.")
    static var systemPurple: Color {
        return Color(uiColor: .systemPurple)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemYellow) instead; this shim will be removed in a future release.")
    static var systemYellow: Color {
        return Color(uiColor: .systemYellow)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemGray) instead; this shim will be removed in a future release.")
    static var systemGray: Color {
        return Color(uiColor: .systemGray)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemGray2) instead; this shim will be removed in a future release.")
    static var systemGray2: Color {
        return Color(uiColor: .systemGray2)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemGray3) instead; this shim will be removed in a future release.")
    static var systemGray3: Color {
        return Color(uiColor: .systemGray3)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemGray4) instead; this shim will be removed in a future release.")
    static var systemGray4: Color {
        return Color(uiColor: .systemGray4)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemGray5) instead; this shim will be removed in a future release.")
    static var systemGray5: Color {
        return Color(uiColor: .systemGray5)
    }

    @available(*, deprecated, message: "Use Color(uiColor: .systemGray6) instead; this shim will be removed in a future release.")
    static var systemGray6: Color {
        return Color(uiColor: .systemGray6)
    }
}
