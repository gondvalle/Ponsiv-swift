import SwiftUI
import Infrastructure

public struct TopBarView: View {
    public struct Configuration {
        public var showBack: Bool
        public var showsCreateLookAction: Bool
        public var showsProfileMenu: Bool

        public init(showBack: Bool = false, showsCreateLookAction: Bool = false, showsProfileMenu: Bool = false) {
            self.showBack = showBack
            self.showsCreateLookAction = showsCreateLookAction
            self.showsProfileMenu = showsProfileMenu
        }
    }

    private let configuration: Configuration
    private let onLogoTap: () -> Void
    private let onBack: () -> Void
    private let onMessages: () -> Void
    private let onCreateLook: () -> Void
    private let onShowMenu: () -> Void

    private let assetService = AssetService()

    public init(
        configuration: Configuration,
        onLogoTap: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onMessages: @escaping () -> Void,
        onCreateLook: @escaping () -> Void,
        onShowMenu: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.onLogoTap = onLogoTap
        self.onBack = onBack
        self.onMessages = onMessages
        self.onCreateLook = onCreateLook
        self.onShowMenu = onShowMenu
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            content
        }
        .frame(height: 96)
        .background(AppTheme.Colors.surface)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1), alignment: .bottom
        )
    }

    private var content: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            HStack(spacing: AppTheme.Spacing.s) {
                if configuration.showBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.001))
                }

                Button(action: onLogoTap) {
                    RemoteImageView(url: assetService.url(for: "logos/Ponsiv.png"), contentMode: .fit)
                        .frame(width: 140, height: 40)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppTheme.Spacing.s) {
                if configuration.showsCreateLookAction {
                    Button(action: onCreateLook) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onMessages) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                    .buttonStyle(.plain)
                }

                if configuration.showsProfileMenu {
                    Button(action: onShowMenu) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.bottom, AppTheme.Spacing.s)
    }
}
