import SwiftUI
#if os(macOS)
import AppKit
#endif

extension Color {
    public static var platformBackground: Color {
        #if os(macOS)
        return Color(nsColor: NSColor.windowBackgroundColor)
        #else
        return Color(.systemGroupedBackground)
        #endif
    }

    public static var platformSecondaryBackground: Color {
        #if os(macOS)
        return Color(nsColor: NSColor.underPageBackgroundColor)
        #else
        return Color(.secondarySystemBackground)
        #endif
    }

    public static var platformCard: Color {
        #if os(macOS)
        return Color(nsColor: NSColor.controlBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
}
