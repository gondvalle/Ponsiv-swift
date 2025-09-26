import SwiftUI
import Core
import Infrastructure

public struct LookSlideView: View {
    private let look: Look
    private let coverURL: URL?
    private let isLiked: Bool
    private let callbacks: ProductSlideView.Callbacks

    @State private var hideOverlay = false

    public init(
        look: Look,
        coverURL: URL?,
        isLiked: Bool,
        callbacks: ProductSlideView.Callbacks
    ) {
        self.look = look
        self.coverURL = coverURL
        self.isLiked = isLiked
        self.callbacks = callbacks
    }

    public var body: some View {
        ZStack {
            RemoteImageView(url: coverURL, contentMode: .fill)
                .ignoresSafeArea()
                .onLongPressGesture(minimumDuration: 0.18) {
                    withAnimation(.easeInOut(duration: 0.2)) { hideOverlay = true }
                } onPressingChanged: { pressing in
                    if !pressing {
                        withAnimation(.easeInOut(duration: 0.2)) { hideOverlay = false }
                    }
                }

            overlay
                .opacity(hideOverlay ? 0 : 1)
        }
        .background(Color.black)
    }

    private var overlay: some View {
        ZStack(alignment: .bottomLeading) {
            infoCard
                .padding(.leading, 32)
                .padding(.bottom, 48)

            buttonColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 28)
                .padding(.top, 120)
        }
        .padding(.bottom, 32)
        .padding(.trailing, 24)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text(look.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(3)
            HStack(spacing: AppTheme.Spacing.s) {
                if let avatarPath = look.author.avatarPath, let url = AssetService().url(for: avatarPath) {
                    RemoteImageView(url: url, contentMode: .fill)
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(AppTheme.Colors.secondaryBackground)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "person")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        )
                }
                Text("Por \(look.author.name)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
        }
        .padding(.vertical, AppTheme.Spacing.m)
        .padding(.horizontal, AppTheme.Spacing.l)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
        .shadow(color: AppTheme.Colors.primaryText.opacity(0.15), radius: 18, x: 0, y: 8)
    }

    private var buttonColumn: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            circleButton(systemName: isLiked ? "heart.fill" : "heart", active: isLiked) {
                HapticsManager.selection()
                callbacks.onLike()
            }
            circleButton(systemName: "square.and.arrow.up") {
                callbacks.onShare()
            }
            circleButton(systemName: "ellipsis.bubble") {
                callbacks.onToggleWardrobe()
            }
        }
    }

    private func circleButton(systemName: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(active ? .white : AppTheme.Colors.primaryText)
                .frame(width: 48, height: 48)
                .background(active ? AppTheme.Colors.primaryText : AppTheme.Colors.surface)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
