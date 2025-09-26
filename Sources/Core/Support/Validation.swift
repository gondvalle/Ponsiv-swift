import Foundation

public enum FormValidator {
    private static let emailRegex = try! NSRegularExpression(
        pattern: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#,
        options: [.caseInsensitive]
    )

    public static func isValidEmail(_ value: String) -> Bool {
        let range = NSRange(location: 0, length: value.utf16.count)
        return emailRegex.firstMatch(in: value, options: [], range: range) != nil
    }

    public static func isValidPassword(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6
    }

    public static func isNonEmpty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
