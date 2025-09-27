import SwiftUI

/**
 * COMPONENTE DE IMAGEN REMOTA REUTILIZABLE
 *
 * Wrapper sobre AsyncImage que proporciona funcionalidades adicionales como:
 * - Placeholder personalizado mientras carga
 * - Soporte para corner radius
 * - ContentMode configurable
 *
 * USADO EXTENSIVAMENTE EN:
 * - ProductSlideView.swift para imágenes de productos (contentMode: .fill)
 * - TopBarView.swift para el logo (contentMode: .fit, 140x40px)
 * - BottomBarView.swift para iconos de navegación (28x28px)
 * - Cualquier lugar que necesite cargar imágenes desde URLs
 *
 * CONFIGURACIONES COMUNES:
 * - Productos: contentMode .fill para llenar todo el espacio
 * - Logos/Iconos: contentMode .fit para mantener proporción
 * - cornerRadius: 0 por defecto, personalizable para bordes redondeados
 */
public struct RemoteImageView: View {
    private let url: URL?               // URL de la imagen a cargar
    private let contentMode: ContentMode // Modo de contenido (.fit, .fill)
    private let cornerRadius: CGFloat    // Radio de bordes redondeados

    public init(url: URL?, contentMode: ContentMode = .fill, cornerRadius: CGFloat = 0) {
        self.url = url
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()                            // Permite redimensionar
                .aspectRatio(contentMode: contentMode) // Aplica modo de contenido
        } placeholder: {
            // PLACEHOLDER: Rectángulo gris mientras carga la imagen
            Rectangle()
                .fill(Color.platformSecondaryBackground)  // Color definido en Color+Platform.swift
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))  // Bordes redondeados
    }
}
