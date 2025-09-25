import SwiftUI

public struct RemoteImageView: View {
    private let url: URL?
    private let contentMode: ContentMode
    private let cornerRadius: CGFloat

    public init(url: URL?, contentMode: ContentMode = .fill, cornerRadius: CGFloat = 0) {
        self.url = url
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } placeholder: {
            Rectangle()
                .fill(Color.platformSecondaryBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
