import SwiftUI
import Foundation
import Combine
import Core

@MainActor
public final class AuthViewModel: ObservableObject {
    public enum Mode: String, CaseIterable, Identifiable {
        case login
        case signup

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .login: return "Iniciar sesión"
            case .signup: return "Crear cuenta"
            }
        }

        public var toggleMessage: String {
            switch self {
            case .login: return "¿No tienes cuenta? Regístrate"
            case .signup: return "¿Ya tienes cuenta? Inicia sesión"
            }
        }
    }

    @Published public var mode: Mode = .login
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var name: String = ""
    @Published public var errorMessage: String?
    @Published public var isSubmitting: Bool = false
    @Published public var showPassword: Bool = false

    public init() {}

    public var canSubmit: Bool {
        guard FormValidator.isNonEmpty(email), FormValidator.isNonEmpty(password) else {
            return false
        }
        if mode == .signup && !FormValidator.isNonEmpty(name) {
            return false
        }
        return true
    }

    public func toggleMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82, blendDuration: 0.2)) {
            mode = mode == .login ? .signup : .login
            errorMessage = nil
            isSubmitting = false
        }
    }

    public func submit(using appModel: AppViewModel) async {
        guard canSubmit else { return }
        errorMessage = nil
        isSubmitting = true
        switch mode {
        case .login:
            let result = await appModel.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            }
        case .signup:
            let request = CreateUserRequest(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                handle: name.lowercased().replacingOccurrences(of: " ", with: "")
            )
            let result = await appModel.signUp(request: request)
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            }
        }
        isSubmitting = false
    }
}
