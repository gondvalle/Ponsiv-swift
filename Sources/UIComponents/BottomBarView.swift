import SwiftUI
import Infrastructure  // Para AssetService definido en Sources/Infrastructure/Support/AssetService.swift

/**
 * MODELO DE ITEM PARA LA BARRA INFERIOR
 * Representa cada tab de navegación con sus iconos y estado
 */
public struct BottomBarItem: Identifiable, Hashable {
    public let id: String           // Identificador único del tab
    public let title: String        // Título del tab (actualmente no se muestra)
    public let iconKey: String      // Path del ícono normal
    public let selectedIconKey: String // Path del ícono seleccionado

    public init(id: String, title: String, iconKey: String, selectedIconKey: String) {
        self.id = id
        self.title = title
        self.iconKey = iconKey
        self.selectedIconKey = selectedIconKey
    }
}

/**
 * BARRA DE NAVEGACIÓN INFERIOR
 *
 * Componente de navegación principal que muestra los tabs de la aplicación.
 * Incluye sistema de badges para el carrito y gestión de estados activos.
 *
 * DIMENSIONES Y DISEÑO:
 * - Iconos: 28x28px cada uno
 * - Badge del carrito: 11px bold, padding 4px horizontal, 2px vertical
 * - Offset del badge: +8px horizontal, -8px vertical
 * - Padding vertical: small del tema
 * - Padding horizontal: medium del tema
 * - Línea superior: 1px con opacidad 0.08
 *
 * DEPENDENCIAS CRUZADAS:
 * - Usa AssetService (Sources/Infrastructure/Support/AssetService.swift) para cargar iconos
 * - Usa AppTheme (Sources/UIComponents/Theme/AppTheme.swift) para colores y espaciados
 * - Usa RemoteImageView (Sources/UIComponents/RemoteImageView.swift) para mostrar iconos
 *
 * LLAMADO DESDE:
 * - RootView (Sources/App/RootView.swift) como navegación principal
 */
public struct BottomBarView: View {
    // PROPIEDADES DEL COMPONENTE
    public var items: [BottomBarItem]              // Lista de tabs a mostrar
    public var selectedID: String                  // ID del tab actualmente seleccionado
    public var cartBadgeValue: Int                 // Número de items en el carrito
    public var onSelect: (BottomBarItem) -> Void   // Callback al seleccionar un tab

    private let assetService = AssetService()       // Servicio para cargar assets remotos

    public init(
        items: [BottomBarItem],
        selectedID: String,
        cartBadgeValue: Int = 0,
        onSelect: @escaping (BottomBarItem) -> Void
    ) {
        self.items = items
        self.selectedID = selectedID
        self.cartBadgeValue = cartBadgeValue
        self.onSelect = onSelect
    }

    /**
     * VISTA PRINCIPAL DE LA BARRA INFERIOR
     *
     * ESTRUCTURA:
     * - HStack principal sin spacing (distribución uniforme)
     * - ForEach para generar cada tab button
     * - VStack por cada tab: ícono + spacer
     * - ZStack para ícono + badge (solo carrito)
     *
     * MEDIDAS ESPECÍFICAS:
     * - Iconos: 28x28px cada uno
     * - Badge: font 11px bold, padding H:4px V:2px, offset +8x -8y
     * - VStack spacing: extra-small del tema
     * - Padding horizontal: medium del tema
     * - Padding vertical: small del tema
     * - Línea superior: 1px altura con opacidad 0.08
     */
    public var body: some View {
        HStack(spacing: 0) {  // Sin spacing para distribución uniforme
            ForEach(items) { item in
                Button {
                    onSelect(item)  // Callback al seleccionar tab
                } label: {
                    VStack(spacing: AppTheme.Spacing.xs) {  // Espaciado extra-small del tema
                        // ÍCONO CON BADGE (si es carrito)
                        ZStack(alignment: .topTrailing) {  // Badge en esquina superior derecha
                            // ÍCONO DEL TAB (normal o seleccionado)
                            RemoteImageView(
                                url: assetService.url(for: selectedID == item.id ? item.selectedIconKey : item.iconKey),
                                contentMode: .fit
                            )
                            .frame(width: 28, height: 28)  // Tamaño fijo: 28x28px

                            // BADGE DEL CARRITO (solo si es carrito y tiene items)
                            if item.id == "cart" && cartBadgeValue > 0 {
                                Text(cartBadgeValue > 99 ? "99+" : "\(cartBadgeValue)")  // Máximo "99+"
                                    .font(.system(size: 11, weight: .bold))  // 11px bold
                                    .foregroundColor(.white)                 // Texto blanco
                                    .padding(.horizontal, 4)                 // Padding H: 4px
                                    .padding(.vertical, 2)                   // Padding V: 2px
                                    .background(Color.black, in: Capsule())  // Fondo negro cápsula
                                    .offset(x: 8, y: -8)                     // Offset: +8x -8y
                            }
                        }

                        // SPACER INVISIBLE (para mantener altura consistente)
                        Rectangle()
                            .fill(Color.clear)       // Invisible
                            .frame(height: 2)        // Altura mínima: 2px
                    }
                    .frame(maxWidth: .infinity)      // Ocupa todo el ancho disponible
                    .padding(.vertical, AppTheme.Spacing.s)  // Padding vertical small del tema
                }
                .buttonStyle(.plain)  // Sin estilo de botón por defecto
            }
        }
        // CONFIGURACIÓN GENERAL DE LA BARRA
        .padding(.horizontal, AppTheme.Spacing.m)    // Padding horizontal medium del tema
        .padding(.top, AppTheme.Spacing.s)           // Padding superior small del tema
        .padding(.bottom, AppTheme.Spacing.s)        // Padding inferior small del tema
        .background(AppTheme.Colors.surface)         // Fondo del tema

        // LÍNEA DIVISORIA SUPERIOR
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))     // Color sutil con 8% opacidad
                .frame(height: 1),                   // Línea de 1px de altura
            alignment: .top                          // Alineada en la parte superior
        )
    }
}
