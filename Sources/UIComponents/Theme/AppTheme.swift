import SwiftUI

public enum AppTheme {
    public enum Colors {
        public static let background = Color(hex: 0xF6F7F9)
        public static let secondaryBackground = Color(hex: 0xF5F7FB)
        public static let surface = Color.white
        public static let surfaceMuted = Color(hex: 0xF3F4F6)
        public static let primaryText = Color.black
        public static let secondaryText = Color.black.opacity(0.6)
        public static let accent = Color(hex: 0x111111)
        public static let accentMuted = Color(hex: 0xE3C393)
        public static let destructive = Color(hex: 0xC00000)
        public static let success = Color(hex: 0x2E7D32)
        public static let warningBackground = Color(hex: 0xFFF3C4)
        public static let successBackground = Color(hex: 0xD8F5D4)
        public static let overlay = Color.black.opacity(0.35)
    }

    public enum Radii {
        public static let xs: CGFloat = 8
        public static let s: CGFloat = 12
        public static let m: CGFloat = 16
        public static let l: CGFloat = 22
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 24
    }

    public enum Shadows {
        public static let card = Color.black.opacity(0.12)
    }
}

public extension Color {
    init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

public extension View {
    func cardBackground(cornerRadius: CGFloat = AppTheme.Radii.m) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.surface)
            )
    }
}
