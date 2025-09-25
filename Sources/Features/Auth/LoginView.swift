import SwiftUI
import Core
import UIComponents

public struct LoginView: View {
    @EnvironmentObject private var appModel: AppViewModel

    @State private var mode: Mode = .login
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var errorMessage: String?
    @State private var isBusy = false

    enum Mode: String, CaseIterable {
        case login = "Iniciar sesión"
        case signup = "Crear cuenta"

        var toggleLabel: String {
            self == .login ? "¿No tienes cuenta? Regístrate" : "¿Ya tienes cuenta? Inicia sesión"
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let logo = appModel.assetURL(for: "logos/Ponsiv.png") {
                        RemoteImageView(url: logo, contentMode: .fit)
                            .frame(width: 220, height: 80)
                            .padding(.top, 40)
                    } else {
                        Spacer().frame(height: 40)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text(mode.rawValue)
                            .font(.title.bold())
                        Text("Accede para guardar tus looks y carrito.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if mode == .signup {
                            #if os(iOS)
                            TextField("Nombre", text: $name)
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            #else
                            TextField("Nombre", text: $name)
                                .padding()
                                .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            #endif
                        }

                        #if os(iOS)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.none)
                            .textContentType(.emailAddress)
                            .padding()
                            .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        SecureField("Contraseña", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        #else
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        SecureField("Contraseña", text: $password)
                            .padding()
                            .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        #endif

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.red)
                        }

                        Button(action: submit) {
                            HStack {
                                if isBusy {
                                    ProgressView()
                                }
                                Text(mode == .login ? "Entrar" : "Crear cuenta")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Color.white)
                        }
                        .disabled(!canSubmit || isBusy)

                        Button(mode.toggleLabel) {
                            withAnimation(.spring) {
                                mode = mode == .login ? .signup : .login
                                errorMessage = nil
                                isBusy = false
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(Color.platformCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color.platformBackground)
        }
    }

    private var canSubmit: Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        if mode == .signup && name.isEmpty { return false }
        return true
    }

    private func submit() {
        guard canSubmit else { return }
        errorMessage = nil
        isBusy = true
        Task {
            switch mode {
            case .login:
                let result = await appModel.login(email: email, password: password)
                await MainActor.run {
                    isBusy = false
                    if case let .failure(error) = result {
                        errorMessage = error.localizedDescription
                    }
                }
            case .signup:
                let request = CreateUserRequest(
                    email: email,
                    password: password,
                    name: name,
                    handle: name.lowercased().replacingOccurrences(of: " ", with: "")
                )
                let result = await appModel.signUp(request: request)
                await MainActor.run {
                    isBusy = false
                    if case let .failure(error) = result {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}
