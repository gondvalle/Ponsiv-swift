import SwiftUI
import Core
import UIComponents
import Infrastructure

public struct LoginView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @StateObject private var viewModel = AuthViewModel()
    private let assetService = AssetService()

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.l) {
                    Spacer(minLength: max(40, proxy.size.height * 0.05))
                    logo
                    card
                    Spacer(minLength: max(24, proxy.safeAreaInsets.bottom))
                }
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.Colors.background)
            .ignoresSafeArea()
        }
    }

    private var logo: some View {
        RemoteImageView(url: assetService.url(for: "logos/Ponsiv.png"), contentMode: .fit)
            .frame(maxWidth: 280, minHeight: 80)
            .padding(.horizontal, AppTheme.Spacing.l)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                Text(viewModel.mode.title)
                    .font(.system(size: 24, weight: .bold))
                Text(viewModel.mode == .login ? "Accede para guardar tus looks y carrito." : "Únete para empezar a crear y guardar looks.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }

            if viewModel.mode == .signup {
                field(label: "Nombre") {
                    #if os(iOS)
                    TextField("Tu nombre", text: $viewModel.name)
                        .textContentType(.name)
                        .keyboardType(.default)
                        .textInputAutocapitalization(.words)
                    #else
                    TextField("Tu nombre", text: $viewModel.name)
                    #endif
                }
            }

            field(label: "Email") {
                #if os(iOS)
                TextField("mail@ejemplo.com", text: $viewModel.email)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.none)
                    .textContentType(.emailAddress)
                #else
                TextField("mail@ejemplo.com", text: $viewModel.email)
                    .disableAutocorrection(true)
                #endif
            }

            field(label: "Contraseña") {
                HStack(spacing: AppTheme.Spacing.s) {
                    Group {
                        if viewModel.showPassword {
                            #if os(iOS)
                            TextField("********", text: $viewModel.password)
                                .textContentType(.password)
                            #else
                            TextField("********", text: $viewModel.password)
                            #endif
                        } else {
                            #if os(iOS)
                            SecureField("********", text: $viewModel.password)
                                .textContentType(.password)
                            #else
                            SecureField("********", text: $viewModel.password)
                            #endif
                        }
                    }

                    Button(action: { viewModel.showPassword.toggle() }) {
                        Text(viewModel.showPassword ? "Ocultar" : "Mostrar")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }

            if let error = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.Colors.destructive)
                }
                .padding(AppTheme.Spacing.m)
                .background(Color(hex: 0xFDECEC))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.s, style: .continuous))
            }

            Button(action: submit) {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text(viewModel.mode == .login ? "Entrar" : "Crear cuenta")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(.white)
                .padding(.vertical, AppTheme.Spacing.m)
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
                .opacity(viewModel.canSubmit ? 1 : 0.6)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)

            Button(action: viewModel.toggleMode) {
                Text(viewModel.mode.toggleMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)
            .padding(.top, AppTheme.Spacing.s)
        }
        .padding(AppTheme.Spacing.l)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.l, style: .continuous))
        .shadow(color: AppTheme.Colors.primaryText.opacity(0.08), radius: 16, x: 0, y: 10)
        .padding(.horizontal, AppTheme.Spacing.l)
        .frame(maxWidth: 420)
    }

    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.Colors.secondaryText)
            content()
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
        }
    }

    private func submit() {
        Task {
            await viewModel.submit(using: appModel)
        }
    }
}
