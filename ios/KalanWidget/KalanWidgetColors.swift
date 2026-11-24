import SwiftUI
import UIKit

/// The home screen widget's colours (Roadmap 31): exact copies of the
/// KalanColors light and dark tokens (lib/core/theme/kalan_colors.dart),
/// checked by test/app/widget_platform_test.dart. Never a new colour; no
/// gradient, shadow or transparency. Follows the phone's light or dark
/// appearance.
enum KalanWidgetColors {
    static let surface = dynamic(light: 0xFCF9F2, dark: 0x19212B)
    static let text = dynamic(light: 0x1A2330, dark: 0xEFE9DD)
    static let textMuted = dynamic(light: 0x566070, dark: 0xA8B0BB)
    static let accent = dynamic(light: 0x1D4E89, dark: 0x8FB8F2)
    static let negative = dynamic(light: 0x8A5A00, dark: 0xEEC56E)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            rgb(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
