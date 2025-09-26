import Foundation

public enum FormatterUtils {
    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let orderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return formatter
    }()

    public static func formatPrice(_ value: Decimal) -> String {
        let number = value as NSDecimalNumber
        if let formatted = priceFormatter.string(from: number) {
            return "\(formatted) €"
        }
        return String(format: "%.2f €", number.doubleValue)
    }

    public static func formatOrderDate(_ date: Date) -> String {
        orderDateFormatter.string(from: date)
    }

    public static func truncate(_ text: String, maxLength: Int) -> String {
        guard maxLength > 0, text.count > maxLength else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}
