import SwiftUI
import Core           // Para el modelo Product definido en Sources/Core/Models/Product.swift
import Infrastructure // Para HapticsManager definido en Sources/Infrastructure/Support/HapticsManager.swift

/**
 * COMPONENTE DE TARJETA DESLIZABLE DE PRODUCTO
 *
 * Componente principal para mostrar productos en formato de tarjeta deslizable similar a TikTok/Instagram.
 * Muestra imagen del producto con controles de interacción superpuestos.
 *
 * DISEÑO Y MEDIDAS PRINCIPALES:
 * - Tamaño: Ocupa toda la pantalla disponible (frame: proxy.size)
 * - Fondo: Color.black para contraste con las imágenes
 * - Capas: ZStack con imagen de fondo + overlay de información y botones
 *
 * DEPENDENCIAS CRUZADAS:
 * - Usa Product model (Sources/Core/Models/Product.swift)
 * - Usa RemoteImageView (Sources/UIComponents/RemoteImageView.swift) para cargar imágenes
 * - Usa AppTheme (Sources/UIComponents/Theme/AppTheme.swift) para colores y espaciados
 * - Usa HapticsManager (Sources/Infrastructure/Support/HapticsManager.swift) para vibración
 *
 * LLAMADO DESDE:
 * - FeedView (Sources/Features/Feed/FeedView.swift) para mostrar productos en el feed principal
 */
public struct ProductSlideView: View {
    /**
     * ESTRUCTURA DE CALLBACKS
     * Define todas las acciones que puede realizar el usuario en la tarjeta del producto
     */
    public struct Callbacks {
        public var onLike: () -> Void           // Marcar/desmarcar like del producto
        public var onShare: () -> Void          // Compartir producto
        public var onAddToCart: () -> Void      // Añadir al carrito
        public var onToggleWardrobe: () -> Void // Añadir/quitar del guardarropa
        public var onOpenDetail: () -> Void     // Abrir vista de detalle del producto

        public init(
            onLike: @escaping () -> Void,
            onShare: @escaping () -> Void,
            onAddToCart: @escaping () -> Void,
            onToggleWardrobe: @escaping () -> Void,
            onOpenDetail: @escaping () -> Void
        ) {
            self.onLike = onLike
            self.onShare = onShare
            self.onAddToCart = onAddToCart
            self.onToggleWardrobe = onToggleWardrobe
            self.onOpenDetail = onOpenDetail
        }
    }

    // PROPIEDADES DEL COMPONENTE
    private let product: Product        // Datos del producto a mostrar
    private let imageURLs: [URL]        // URLs de las imágenes del producto
    private let isLiked: Bool          // Estado del like del usuario
    private let isInWardrobe: Bool     // Si está en el guardarropa del usuario
    private let callbacks: Callbacks    // Funciones de callback para las acciones

    // ESTADOS INTERNOS
    @State private var selectedIndex: Int = 0    // Índice de imagen actualmente visible
    @State private var hideOverlay = false       // Controla visibilidad del overlay (para vista sin distracciones)
    @State private var showSizeSheet = false     // Controla visibilidad del selector de tallas
    @State private var scale: CGFloat = 1.0      // Escala para el zoom con pellizco
    @State private var offset: CGSize = .zero    // Offset para centrar zoom en punto de toque
    @State private var tapLocation: CGPoint = .zero  // Posición del último tap

    public init(
        product: Product,
        imageURLs: [URL],
        isLiked: Bool,
        isInWardrobe: Bool,
        callbacks: Callbacks
    ) {
        self.product = product
        self.imageURLs = imageURLs
        self.isLiked = isLiked
        self.isInWardrobe = isInWardrobe
        self.callbacks = callbacks
    }

    /**
     * VISTA PRINCIPAL DEL COMPONENTE
     *
     * ESTRUCTURA:
     * - GeometryReader: Lee el tamaño disponible de la pantalla
     * - ZStack: Apila imagen de fondo + overlay de información
     * - Sheet: Modal para selección de tallas
     *
     * MEDIDAS Y POSICIONAMIENTO:
     * - frame: width/height = proxy.size (toda la pantalla disponible)
     * - background: Color.black (fondo negro para contraste)
     * - opacity: hideOverlay controla visibilidad del overlay (0 = invisible, 1 = visible)
     */
    public var body: some View {
        GeometryReader { proxy in  // Lee dimensiones disponibles de la pantalla
            ZStack {
                // CAPA DE FONDO: Paginador de imágenes del producto
                imagePager(size: proxy.size)

                // CAPA SUPERIOR: Overlay con información del producto y botones de acción
                overlay(size: proxy.size)
                    .opacity(hideOverlay ? 0 : 1)  // Se oculta al mantener presionado para vista limpia
            }
            // CONFIGURACIÓN DE TAMAÑO: Ocupa toda la pantalla disponible
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.black)  // Fondo negro para contraste con imágenes
        }
        // MODAL DE SELECCIÓN DE TALLAS
        .sheet(isPresented: $showSizeSheet) {
            sizeSheet
                .presentationDetents([.medium])  // Modal de altura media
        }
    }

    /**
     * PAGINADOR DE IMÁGENES DEL PRODUCTO
     *
     * FUNCIONALIDAD:
     * - Permite deslizar horizontalmente entre las imágenes del producto
     * - Gesto de mantener presionado oculta el overlay para vista limpia
     * - Zoom con pellizco o doble tap (ideal para simulador)
     *
     * MEDIDAS Y POSICIONAMIENTO:
     * - frame: width/height = size (ocupa toda la pantalla)
     * - scaleEffect: Aplica zoom controlado por gestos
     * - clipped(): Recorta imagen que se salga del marco
     * - ignoresSafeArea(): Ignora áreas seguras para imagen completa
     *
     * GESTOS:
     * - Doble tap: Toggle zoom 1x/2x centrado en punto de toque
     * - Long press (0.18s): Oculta overlay, se restaura al soltar
     * - Swipe horizontal: Navegación entre productos (no interferido)
     */
    private func imagePager(size: CGSize) -> some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                ZStack {
                    RemoteImageView(url: url, contentMode: .fill)  // Componente definido en RemoteImageView.swift
                        .frame(width: size.width, height: size.height)
                        .scaleEffect(scale, anchor: .center)  // Zoom centrado
                        .offset(offset)  // Offset para posicionar el zoom
                        .clipped()
                        .ignoresSafeArea()

                    // Capa invisible para capturar gestos (sin interferir con swipe)
                    Color.clear
                        .frame(width: size.width, height: size.height)
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 0.18) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hideOverlay = true
                            }
                        } onPressingChanged: { pressing in
                            if !pressing {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    hideOverlay = false
                                }
                            }
                        }
                        .onTapGesture(count: 2, coordinateSpace: .local) { location in
                            // Doble tap con posición
                            let centerX = size.width / 2
                            let centerY = size.height / 2

                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                } else {
                                    scale = 2.0
                                    // Calcular offset para centrar zoom en el punto tocado
                                    offset = CGSize(
                                        width: (centerX - location.x) * 0.5,
                                        height: (centerY - location.y) * 0.5
                                    )
                                }
                            }
                        }
                }
                .tag(index)
            }
        }
        // ESTILO DE PAGINACIÓN: Sin indicadores de página en iOS
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))  // Sin puntos indicadores
        #else
        .tabViewStyle(.automatic)  // Estilo automático en otras plataformas
        #endif
        // RESET ZOOM Y ESTADOS AL CAMBIAR DE IMAGEN
        .onChange(of: selectedIndex) {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1.0  // Vuelve al zoom original al cambiar de imagen
                offset = .zero  // Reset offset del zoom
            }
            hideOverlay = false  // Asegura que el overlay se muestre
            tapLocation = .zero  // Reset posición del tap
        }
    }

    /**
     * OVERLAY DE INFORMACIÓN Y CONTROLES
     *
     * ESTRUCTURA Y POSICIONAMIENTO:
     * - ZStack(alignment: .bottomLeading): Alinea contenido abajo-izquierda
     * - infoCard: Información del producto (abajo-izquierda)
     * - buttonColumn: Botones de acción (arriba-derecha)
     *
     * MEDIDAS ESPECÍFICAS:
     * - infoCard padding: .leading 32px, .bottom 48px
     * - buttonColumn padding: .trailing 28px, .top 120px
     * - Overlay padding: .bottom 32px, .trailing 24px
     * - frame: size completo con alignment .topLeading
     */
    private func overlay(size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {  // Alineación principal abajo-izquierda
            // TARJETA DE INFORMACIÓN DEL PRODUCTO (esquina inferior izquierda)
            infoCard
                .padding(.leading, 25)   // 25px desde el borde izquierdo
                .padding(.bottom, 15)    // 20px desde el borde inferior

            // COLUMNA DE BOTONES DE ACCIÓN (lado derecho superior)
            buttonColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 3)  // 3px desde el borde derecho
                .padding(.top, 170)      // 170px desde el borde superior
        }
        // PADDING GENERAL DEL OVERLAY
        .padding(.bottom, 32)    // 32px padding inferior adicional
        .padding(.trailing, 24)  // 24px padding derecho adicional
        // TAMAÑO: Ocupa toda la pantalla con alineación superior-izquierda
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    /**
     * TARJETA DE INFORMACIÓN DEL PRODUCTO
     *
     * CONTENIDO:
     * - Título del producto (font: 16px, weight: semibold, max 3 líneas)
     * - Marca (font: 13px, weight: regular, color secundario)
     * - Precio (font: 14px, weight: bold)
     *
     * MEDIDAS Y DISEÑO:
     * - VStack spacing: AppTheme.Spacing.xs
     * - Padding vertical: AppTheme.Spacing.m
     * - Padding horizontal: AppTheme.Spacing.l
     * - Ancho: min 220px, ideal 260px, max 280px
     * - Fondo: AppTheme.Colors.surface
     * - Border radius: AppTheme.Radii.m con estilo continuo
     * - Sombra: color primary.opacity(0.15), radius 18px, offset x:0 y:8
     *
     * INTERACCIÓN:
     * - Tap gesture: Llama callbacks.onOpenDetail (navega a ProductDetailView)
     */
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {  // Espaciado extra-small del tema
            // TÍTULO DEL PRODUCTO
            Text(product.title)
                .font(.system(size: 16, weight: .semibold))  // 16px, peso semi-negrita
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(3)  // Máximo 3 líneas

            // MARCA DEL PRODUCTO
            Text(product.brand)
                .font(.system(size: 13, weight: .regular))   // 13px, peso normal
                .foregroundColor(AppTheme.Colors.secondaryText)

            // PRECIO DEL PRODUCTO
            Text(product.displayPrice)
                .font(.system(size: 14, weight: .bold))      // 14px, peso negrita
                .foregroundColor(AppTheme.Colors.primaryText)
        }
        // PADDING INTERNO
        .padding(.vertical, AppTheme.Spacing.m)      // Padding vertical medio
        .padding(.horizontal, AppTheme.Spacing.l)    // Padding horizontal grande

        // DIMENSIONES DE LA TARJETA
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 280, alignment: .leading)

        // ESTILO VISUAL
        .background(AppTheme.Colors.surface)  // Color de fondo definido en AppTheme.swift
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))  // Bordes redondeados
        .shadow(color: AppTheme.Colors.primaryText.opacity(0.15), radius: 18, x: 0, y: 8)  // Sombra sutil

        // INTERACCIÓN: Tap para abrir detalle del producto
        .onTapGesture(perform: callbacks.onOpenDetail)  // Navega a ProductDetailView
    }

    /**
     * COLUMNA DE BOTONES DE ACCIÓN
     *
     * BOTONES (de arriba hacia abajo):
     * 1. Like/Unlike - icono: heart (vacío) / heart.fill (lleno)
     * 2. Compartir - icono: square.and.arrow.up
     * 3. Carrito - icono: cart (abre selector de tallas si aplica)
     * 4. Guardarropa - icono: briefcase (vacío) / briefcase.fill (lleno)
     *
     * MEDIDAS:
     * - VStack spacing: AppTheme.Spacing.l (espaciado grande entre botones)
     * - Cada botón: 48x48px (definido en circleButton)
     *
     * FEEDBACK HÁPTICO:
     * - Like/Guardarropa: HapticsManager.selection() (vibración suave)
     * - Carrito: HapticsManager.success() (vibración de éxito al añadir)
     */
    private var buttonColumn: some View {
        VStack(spacing: AppTheme.Spacing.l) {  // Espaciado grande del tema entre botones
            // BOTÓN DE LIKE/UNLIKE
            circleButton(systemName: isLiked ? "heart.fill" : "heart", active: isLiked) {
                HapticsManager.selection()  // Feedback háptico definido en HapticsManager.swift
                callbacks.onLike()
            }

            // BOTÓN DE COMPARTIR
            circleButton(systemName: "square.and.arrow.up") {
                callbacks.onShare()  // Abre ShareSheet definido en ShareSheet.swift
            }

            // BOTÓN DE CARRITO
            circleButton(systemName: "cart") {
                if product.sizes.isEmpty {
                    // Si no hay tallas, añadir directamente al carrito
                    callbacks.onAddToCart()
                    HapticsManager.success()  // Feedback háptico de éxito
                } else {
                    // Si hay tallas, mostrar selector de tallas
                    showSizeSheet = true
                }
            }

            // BOTÓN DE GUARDARROPA
            circleButton(systemName: isInWardrobe ? "briefcase.fill" : "briefcase", active: isInWardrobe) {
                HapticsManager.selection()  // Feedback háptico de selección
                callbacks.onToggleWardrobe()
            }
        }
    }

    /**
     * BOTÓN CIRCULAR REUTILIZABLE
     *
     * PARÁMETROS:
     * - systemName: Nombre del ícono de SF Symbols
     * - active: Si está activo (cambia colores de fondo y texto)
     * - action: Función a ejecutar al presionar
     *
     * MEDIDAS EXACTAS:
     * - Tamaño del botón: 48x48px
     * - Tamaño del ícono: 18px, peso semibold
     * - Forma: Circle() (círculo perfecto)
     * - Sombra: radius 12px, offset x:0 y:6, opacity 0.1
     *
     * COLORES:
     * - Activo: fondo primaryText (oscuro), texto white
     * - Inactivo: fondo surface (claro), texto primaryText
     */
    private func circleButton(systemName: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))  // 18px, peso semi-negrita
                // COLORES CONDICIONALES según estado activo
                .foregroundColor(active ? .white : AppTheme.Colors.primaryText)
                // TAMAÑO FIJO: 48x48px
                .frame(width: 48, height: 48)
                // FONDO CONDICIONAL según estado activo
                .background(active ? AppTheme.Colors.primaryText : AppTheme.Colors.surface)
                .clipShape(Circle())  // Forma circular perfecta
                // SOMBRA SUTIL: 12px radius, 6px offset vertical
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)  // Sin estilo de botón por defecto
    }

    private var sizeSheet: some View {
        NavigationView {
            List(product.sizes, id: \.self) { size in
                Button {
                    showSizeSheet = false
                    callbacks.onAddToCart()
                    HapticsManager.success()
                } label: {
                    Text(size)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, AppTheme.Spacing.s)
            }
            .navigationTitle("Elige tu talla")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showSizeSheet = false }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showSizeSheet = false }
                }
                #endif
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}
