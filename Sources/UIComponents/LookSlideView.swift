import SwiftUI
import Core

public struct LookSlideView: View {
    private let look: Look
    private let coverURL: URL?
    private let isLiked: Bool
    private let callbacks: ProductSlideView.Callbacks

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
            RemoteImageView(url: coverURL)
                .ignoresSafeArea()
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(look.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                        Text("Por \(look.author.name)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    VStack(spacing: 16) {
                        circleButton(systemName: isLiked ? "heart.fill" : "heart") {
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
                .padding(24)
            }
        }
        .background(Color.black)
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(.regularMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
