import Foundation
import Combine
import Core

@MainActor
public final class FeedViewModel: ObservableObject {
    public struct Slide: Identifiable, Hashable {
        public let id: String
        public let product: Product
    }

    @Published public private(set) var slides: [Slide] = []

    private var appModel: AppViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var baseProducts: [Product] = []
    private var launch: FeedLaunch?
    private var chunkSize: Int = 0
    private let maxChunks = 3
    private var isConfigured = false

    public init() {}

    public func configure(appModel: AppViewModel, launch: FeedLaunch?) {
        self.launch = launch
        if isConfigured {
            rebuildBaseProducts(source: appModel.products)
            return
        }
        self.appModel = appModel
        isConfigured = true

        appModel.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.rebuildBaseProducts(source: products)
            }
            .store(in: &cancellables)

        rebuildBaseProducts(source: appModel.products)
    }

    public func updateLaunch(_ launch: FeedLaunch?) {
        self.launch = launch
        if let appModel {
            rebuildBaseProducts(source: appModel.products)
        }
    }

    private func rebuildBaseProducts(source products: [Product]) {
        guard !products.isEmpty || !(launch?.products.isEmpty ?? true) else {
            baseProducts = []
            slides = []
            return
        }
        var base = launch?.products ?? products
        if base.isEmpty { base = products }
        if let start = launch?.startProduct.id {
            base = reorder(base, startID: start)
        }
        baseProducts = base
        chunkSize = max(1, baseProducts.count)
        slides = makeWarmSlides()
    }

    private func reorder(_ products: [Product], startID: String) -> [Product] {
        guard let index = products.firstIndex(where: { $0.id == startID }), index > 0 else { return products }
        return Array(products[index...]) + Array(products[..<index])
    }

    private func makeWarmSlides() -> [Slide] {
        guard chunkSize > 0 else { return [] }
        return makeChunk() + makeChunk()
    }

    private func makeChunk() -> [Slide] {
        guard !baseProducts.isEmpty else { return [] }
        return baseProducts.shuffled().enumerated().map { offset, product in
            Slide(id: "\(product.id)-\(UUID().uuidString)-\(offset)", product: product)
        }
    }

    public func ensureBuffer(after index: Int) {
        guard chunkSize > 0 else { return }
        let threshold = max(1, slides.count - max(1, chunkSize / 2))
        if index >= threshold {
            slides.append(contentsOf: makeChunk())
        }
    }

    public func trimIfNeeded(currentIndex: Int) {
        guard chunkSize > 0, slides.count > chunkSize * maxChunks, currentIndex > chunkSize else { return }
        slides.removeFirst(chunkSize)
    }
}
