import SwiftUI

public struct CollapsibleHeaderScrollView<Content: View, Header: View, Sticky: View>: View {
    public typealias RenderHeader = (_ progress: CGFloat, _ offset: CGFloat) -> Header
    public typealias RenderSticky = (_ progress: CGFloat, _ offset: CGFloat) -> Sticky

    private let headerHeight: CGFloat
    private let stickyHeight: CGFloat
    private let renderHeader: RenderHeader
    private let renderSticky: RenderSticky?
    private let content: Content

    @State private var scrollOffset: CGFloat = .zero

    public init(
        headerHeight: CGFloat = 220,
        stickyHeight: CGFloat = 0,
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: @escaping RenderHeader,
        @ViewBuilder sticky: @escaping RenderSticky
    ) {
        self.headerHeight = headerHeight
        self.stickyHeight = stickyHeight
        self.renderHeader = header
        self.renderSticky = stickyHeight > 0 ? sticky : nil
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: headerHeight + stickyHeight)
                    content
                }
                .background(GeometryReader { proxy in
                    Color.clear.preference(
                        key: OffsetPreferenceKey.self,
                        value: -proxy.frame(in: .named("collapsibleScroll")).origin.y
                    )
                })
            }
            .coordinateSpace(name: "collapsibleScroll")
            .onPreferenceChange(OffsetPreferenceKey.self) { value in
                scrollOffset = max(0, value)
            }

            headerView
            stickyView
        }
    }

    private var headerView: some View {
        let progress = min(1, max(0, scrollOffset / max(headerHeight, 1)))
        return renderHeader(progress, scrollOffset)
            .frame(height: max(headerHeight - scrollOffset, 0))
            .clipped()
            .frame(height: headerHeight, alignment: .top)
            .background(AppTheme.Colors.surface)
    }

    private var stickyView: some View {
        Group {
            if let renderSticky {
                let progress = min(1, max(0, scrollOffset / max(headerHeight, 1)))
                renderSticky(progress, scrollOffset)
                    .frame(height: stickyHeight)
                    .offset(y: max(headerHeight - scrollOffset, 0))
                    .background(AppTheme.Colors.surface)
            }
        }
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
