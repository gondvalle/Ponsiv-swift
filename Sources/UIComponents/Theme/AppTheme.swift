import SwiftUI

/**
 * SISTEMA DE DISEÑO DE LA APLICACIÓN PONSIV
 *
 * Define todos los valores de diseño consistentes utilizados en toda la aplicación.
 * Este archivo es FUNDAMENTAL y es referenciado desde prácticamente todos los componentes UI.
 *
 * USADO EN TODOS LOS ARCHIVOS DE UI COMO:
 * - ProductSlideView.swift - para colores, espaciados y radios
 * - TopBarView.swift - para colores y espaciados
 * - BottomBarView.swift - para colores y espaciados
 * - FeedView.swift - para espaciados
 * - RootView.swift - para colores de fondo
 * - Y muchos más componentes...
 */
public enum AppTheme {
    /**
     * SISTEMA DE COLORES
     * Paleta completa de colores de la aplicación con valores hexadecimales específicos
     */
    public enum Colors {
        // COLORES DE FONDO
        public static let background = Color(hex: 0xF6F7F9)          // #F6F7F9 - Fondo principal gris muy claro
        public static let secondaryBackground = Color(hex: 0xF5F7FB)  // #F5F7FB - Fondo secundario
        public static let surface = Color.white                      // #FFFFFF - Superficie de tarjetas y componentes

        // FONDOS ALTERNATIVOS
        public static let surfaceMuted = Color(hex: 0xF3F4F6)        // #F3F4F6 - Superficie silenciada

        // COLORES DE TEXTO
        public static let primaryText = Color.black                  // #000000 - Texto principal
        public static let secondaryText = Color.black.opacity(0.6)   // #000000 60% - Texto secundario

        // COLORES DE ACENTO
        public static let accent = Color(hex: 0x111111)              // #111111 - Acento principal (casi negro)
        public static let accentMuted = Color(hex: 0xE3C393)         // #E3C393 - Acento silenciado (beige)

        // COLORES DE ESTADO
        public static let destructive = Color(hex: 0xC00000)         // #C00000 - Rojo para acciones destructivas
        public static let success = Color(hex: 0x2E7D32)             // #2E7D32 - Verde para éxito

        // FONDOS DE ESTADO
        public static let warningBackground = Color(hex: 0xFFF3C4)   // #FFF3C4 - Fondo amarillo para advertencias
        public static let successBackground = Color(hex: 0xD8F5D4)   // #D8F5D4 - Fondo verde para éxito

        // OVERLAYS
        public static let overlay = Color.black.opacity(0.35)        // Negro 35% - Para overlays y modales
    }

    /**
     * SISTEMA DE RADIOS DE BORDE
     * Valores estándar para bordes redondeados en orden de tamaño
     */
    public enum Radii {
        public static let xs: CGFloat = 8   // 8px - Extra pequeño
        public static let s: CGFloat = 12   // 12px - Pequeño
        public static let m: CGFloat = 16   // 16px - Medio (usado frecuentemente)
        public static let l: CGFloat = 22   // 22px - Grande
    }

    /**
     * SISTEMA DE ESPACIADO
     * Valores estándar para padding, margin y spacing en orden de tamaño
     */
    public enum Spacing {
        public static let xs: CGFloat = 4   // 4px - Extra pequeño
        public static let s: CGFloat = 8    // 8px - Pequeño
        public static let m: CGFloat = 12   // 12px - Medio
        public static let l: CGFloat = 16   // 16px - Grande (muy usado)
        public static let xl: CGFloat = 24  // 24px - Extra grande
    }

    /**
     * SISTEMA DE SOMBRAS
     * Colores estándar para sombras con opacidades predefinidas
     */
    public enum Shadows {
        public static let card = Color.black.opacity(0.12)  // Negro 12% - Sombra estándar para tarjetas
    }
}

/**
 * EXTENSIÓN DE COLOR PARA VALORES HEXADECIMALES
 * Permite crear colores usando valores hexadecimales enteros (ej: 0xFF0000 para rojo)
 */
public extension Color {
    init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255    // Extrae componente rojo
        let green = Double((hex >> 8) & 0xFF) / 255   // Extrae componente verde
        let blue = Double(hex & 0xFF) / 255           // Extrae componente azul
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

/**
 * EXTENSIÓN DE VISTA PARA FONDO DE TARJETA
 * Modifier reutilizable que aplica el estilo estándar de tarjeta con fondo y bordes redondeados
 *
 * USADO EN:
 * - ProductSlideView.swift para la tarjeta de información del producto
 * - Cualquier componente que necesite estilo de tarjeta estándar
 */
public extension View {
    func cardBackground(cornerRadius: CGFloat = AppTheme.Radii.m) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)  // Bordes redondeados continuos
                    .fill(AppTheme.Colors.surface)  // Fondo blanco del tema
            )
    }
}
