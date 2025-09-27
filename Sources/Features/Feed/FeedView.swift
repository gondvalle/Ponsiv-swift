import SwiftUI
import Core         // Para modelo Product definido en Sources/Core/Models/Product.swift
import UIComponents // Para ProductSlideView definido en Sources/UIComponents/ProductSlideView.swift

/**
 * VISTA PRINCIPAL DEL FEED DE PRODUCTOS
 *
 * Vista principal de la aplicación que muestra productos en formato de carrusel vertical
 * similar a TikTok/Instagram. Cada producto ocupa toda la pantalla y se puede deslizar
 * verticalmente entre productos.
 *
 * FUNCIONALIDADES:
 * - Scroll vertical paginado entre productos
 * - Integración con ProductSlideView para cada producto
 * - Gestión de likes, guardarropa, carrito y compartir
 * - Navegación a detalle de producto
 * - Lanzamiento con producto específico (launch)
 *
 * DEPENDENCIAS CRUZADAS:
 * - AppViewModel (Sources/Features/Shared/AppViewModel.swift) - Estado global
 * - FeedViewModel (Sources/Features/Feed/FeedViewModel.swift) - Estado local del feed
 * - ProductSlideView (Sources/UIComponents/ProductSlideView.swift) - Componente de producto
 * - FeedLaunch (Sources/Features/Feed/FeedLaunch.swift) - Configuración de lanzamiento
 * - ShareSheet (Sources/UIComponents/ShareSheet.swift) - Modal de compartir
 *
 * LLAMADO DESDE:
 * - RootView (Sources/App/RootView.swift) como tab principal
 * - ExploreView puede navegar aquí con configuración específica
 */
public struct FeedView: View {
    // MODELOS DE DATOS
    @EnvironmentObject private var appModel: AppViewModel  // Modelo global inyectado desde RootView
    @StateObject private var viewModel = FeedViewModel()   // Modelo local del feed

    // CALLBACKS Y CONFIGURACIÓN
    private let onOpenDetail: (Product) -> Void            // Callback para abrir detalle del producto
    private let launch: FeedLaunch?                        // Configuración de lanzamiento específico

    // ESTADO LOCAL
    @State private var selection: String = ""              // ID del producto seleccionado para scroll
    @State private var shareProduct: Product?              // Producto a compartir (abre ShareSheet)

    public init(onOpenDetail: @escaping (Product) -> Void, launch: FeedLaunch? = nil) {
        self.onOpenDetail = onOpenDetail
        self.launch = launch
    }

    /**
     * VISTA PRINCIPAL DEL FEED
     *
     * ESTRUCTURA DE SCROLL PAGINADO:
     * - GeometryReader: Lee el tamaño de pantalla disponible
     * - ScrollViewReader: Permite scroll programático a productos específicos
     * - ScrollView vertical sin indicadores
     * - LazyVStack sin spacing para scroll perfecto entre productos
     *
     * MEDIDAS Y COMPORTAMIENTO:
     * - Cada ProductSlideView: width/height = proxy.size (pantalla completa)
     * - spacing: 0 (productos adyacentes sin separación)
     * - scrollTargetBehavior(.paging): Snap a productos completos
     * - onChange con animación: 0.3s easeInOut para scroll programático
     *
     * INTEGRACIÓN DE DATOS:
     * - viewModel.slides: Lista de productos del feed
     * - appModel: Proporciona imágenes, likes, guardarropa, carrito
     * - Callbacks: Conecta acciones de ProductSlideView con AppViewModel
     */
    public var body: some View {
        GeometryReader { proxy in  // Lee dimensiones de pantalla disponible
            ScrollViewReader { scrollProxy in  // Permite scroll programático
                ScrollView(.vertical, showsIndicators: false) {  // Scroll vertical sin indicadores
                    LazyVStack(spacing: 0) {  // Sin spacing para transiciones perfectas
                        ForEach(viewModel.slides) { slide in  // Itera sobre productos del feed
                            ProductSlideView(  // Componente definido en ProductSlideView.swift
                                product: slide.product,
                                // INTEGRACIÓN CON APPMODEL: Estado y datos del producto
                                imageURLs: appModel.productImages(for: slide.product),  // Imágenes del producto
                                isLiked: appModel.likedProductIDs.contains(slide.product.id),  // Estado de like
                                isInWardrobe: appModel.wardrobeProductIDs.contains(slide.product.id),  // Estado guardarropa

                                // CALLBACKS: Conecta acciones del producto con la lógica global
                                callbacks: .init(
                                    onLike: { appModel.toggleLike(for: slide.product) },          // Toggle like
                                    onShare: { shareProduct = slide.product },                    // Preparar compartir
                                    onAddToCart: { appModel.addToCart(productID: slide.product.id) },  // Añadir a carrito
                                    onToggleWardrobe: { appModel.toggleWardrobe(for: slide.product) },  // Toggle guardarropa
                                    onOpenDetail: { onOpenDetail(slide.product) }                // Navegar a detalle
                                )
                            )
                            // TAMAÑO: Cada slide ocupa toda la pantalla
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .id(slide.id)  // ID para scroll programático
                        }
                    }
                }
                // CONFIGURACIÓN DEL SCROLL
                .frame(width: proxy.size.width, height: proxy.size.height)  // Tamaño completo
                .scrollTargetBehavior(.paging)  // Comportamiento de paginación (snap a productos)

                // SCROLL PROGRAMÁTICO: Navega a producto específico cuando cambia selection
                .onChange(of: selection) { _, newSelection in
                    if !newSelection.isEmpty {
                        withAnimation(.easeInOut(duration: 0.3)) {  // Animación suave de 0.3s
                            scrollProxy.scrollTo(newSelection, anchor: .top)
                        }
                    }
                }
            }
            .background(Color.black)
            .ignoresSafeArea(.all)
        }
        .ignoresSafeArea(.all)
        .task(id: launch?.id) {
            viewModel.configure(appModel: appModel, launch: launch)
            if let first = viewModel.slides.first?.id {
                selection = first
            }
        }
        .onChange(of: viewModel.slides) { _, slides in
            if slides.contains(where: { $0.id == selection }) == false {
                selection = slides.first?.id ?? ""
            }
        }
        .onChange(of: selection) { _, id in
            guard let index = viewModel.slides.firstIndex(where: { $0.id == id }) else { return }
            viewModel.ensureBuffer(after: index)
            viewModel.trimIfNeeded(currentIndex: index)
        }
        .sheet(item: $shareProduct) { product in
            ShareSheet(items: [product.title, product.displayPrice])
        }
    }
}
