import SwiftUI
import Core
import UIComponents

public struct LookDetailView: View {
    @EnvironmentObject private var appModel: AppViewModel
    let looks: [Look]
    let startLook: Look

    @Environment(\.dismiss) private var dismiss
    @State private var shareLook: Look?
    @State private var selection: String = ""

    public init(looks: [Look], startLook: Look) {
        self.looks = looks
        self.startLook = startLook
    }

    public var body: some View {
        GeometryReader { proxy in
            TabView(selection: $selection) {
                ForEach(looks) { look in
                    LookSlideView(
                        look: look,
                        coverURL: appModel.lookCoverURL(look),
                        isLiked: appModel.likedProductIDs.contains(look.id),
                        callbacks: .init(
                            onLike: { appModel.toggleLike(lookID: look.id) },
                            onShare: { shareLook = look },
                            onAddToCart: {},
                            onToggleWardrobe: {},
                            onOpenDetail: {}
                        )
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: proxy.size.height, height: proxy.size.width)
                    .tag(look.id)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            .tabViewStyle(.automatic)
            #endif
            .rotationEffect(.degrees(-90))
            .frame(width: proxy.size.width, height: proxy.size.height)
            .ignoresSafeArea()
            .onAppear {
                selection = startLook.id
            }
        }
        .background(Color.black)
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cerrar") { dismiss() }
                    .foregroundStyle(.white)
            }
        }
        #endif
        .sheet(item: $shareLook) { look in
            ShareSheet(items: [look.title])
        }
    }
}
