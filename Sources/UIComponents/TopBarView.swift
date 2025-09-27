import SwiftUI
import Infrastructure  // Para AssetService definido en Sources/Infrastructure/Support/AssetService.swift

/**
 * BARRA SUPERIOR DE NAVEGACIÓN
 *
 * Componente de navegación superior que se adapta según el contexto de la pantalla.
 * Contiene logo centralizado, botones de navegación y acciones contextuales.
 *
 * DIMENSIONES FIJAS:
 * - Altura total: 96px (incluye spacer para safe area)
 * - Altura del contenido: ~44px
 * - Ancho del logo: 140px x 40px (con padding vertical 4px)
 * - Botones de acción: 22-24px de font size
 * - Botón back: 40x40px con ícono de 18px
 *
 * DEPENDENCIAS CRUZADAS:
 * - Usa AssetService (Sources/Infrastructure/Support/AssetService.swift) para cargar logo
 * - Usa AppTheme (Sources/UIComponents/Theme/AppTheme.swift) para colores y espaciados
 * - Usa RemoteImageView (Sources/UIComponents/RemoteImageView.swift) para mostrar logo
 *
 * LLAMADO DESDE:
 * - RootView (Sources/App/RootView.swift) como barra superior principal
 */
public struct TopBarView: View {
    /**
     * CONFIGURACIÓN DE LA BARRA SUPERIOR
     * Controla qué elementos se muestran según el contexto de navegación
     */
    public struct Configuration {
        public var showBack: Bool              // Muestra botón de retroceso
        public var showsCreateLookAction: Bool // Muestra botón "+" para crear look
        public var showsProfileMenu: Bool      // Muestra menú hamburguesa de perfil

        public init(showBack: Bool = false, showsCreateLookAction: Bool = false, showsProfileMenu: Bool = false) {
            self.showBack = showBack
            self.showsCreateLookAction = showsCreateLookAction
            self.showsProfileMenu = showsProfileMenu
        }
    }

    // PROPIEDADES DEL COMPONENTE
    private let configuration: Configuration  // Configuración de visibilidad de elementos
    private let onLogoTap: () -> Void        // Callback al tocar el logo (navega al feed)
    private let onBack: () -> Void           // Callback del botón de retroceso
    private let onMessages: () -> Void       // Callback del botón de mensajes
    private let onCreateLook: () -> Void     // Callback del botón crear look
    private let onShowMenu: () -> Void       // Callback del menú de perfil

    private let assetService = AssetService() // Servicio para cargar assets remotos

    public init(
        configuration: Configuration,
        onLogoTap: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onMessages: @escaping () -> Void,
        onCreateLook: @escaping () -> Void,
        onShowMenu: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.onLogoTap = onLogoTap
        self.onBack = onBack
        self.onMessages = onMessages
        self.onCreateLook = onCreateLook
        self.onShowMenu = onShowMenu
    }

    /**
     * VISTA PRINCIPAL DE LA BARRA SUPERIOR
     *
     * ESTRUCTURA:
     * - VStack: Spacer arriba + contenido abajo (empuja contenido hacia abajo)
     * - Altura fija: 96px total (incluye espacio para safe area)
     * - Fondo: AppTheme.Colors.surface
     * - Borde inferior: línea sutil de 1px con opacidad 0.08
     *
     * POSICIONAMIENTO:
     * - Spacer(minLength: 0): Empuja contenido hacia la parte inferior
     * - content: Contenido real de la barra (logo + botones)
     * - overlay: Línea divisoria en la parte inferior
     */
    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)  // Empuja contenido hacia abajo para safe area
            content                // Contenido principal de la barra
        }
        // CONFIGURACIÓN DE TAMAÑO Y ESTILO
        .frame(height: 96)                           // Altura fija: 96px
        .background(AppTheme.Colors.surface)         // Fondo del tema
        .overlay(
            // LÍNEA DIVISORIA INFERIOR
            Rectangle()
                .fill(Color.black.opacity(0.08))     // Color sutil con 8% opacidad
                .frame(height: 1),                   // Línea de 1px de altura
            alignment: .bottom                        // Alineada en la parte inferior
        )
    }

    /**
     * CONTENIDO PRINCIPAL DE LA BARRA
     *
     * LAYOUT HORIZONTAL:
     * - Lado izquierdo: [Botón Back (condicional)] + Logo
     * - Lado derecho: [Mensajes/Crear Look] + [Menú (condicional)]
     *
     * MEDIDAS ESPECÍFICAS:
     * - HStack principal: spacing small del tema
     * - Botón back: 40x40px con ícono 18px medium
     * - Logo: 140x40px con padding vertical 4px
     * - Botones derecha: altura 44px
     * - Iconos mensajes: 22px regular
     * - Iconos crear/menú: 24px (crear: semibold, menú: regular)
     * - Padding horizontal: large del tema
     * - Padding bottom: small del tema
     */
    private var content: some View {
        HStack(spacing: AppTheme.Spacing.s) {  // Espaciado small del tema
            // LADO IZQUIERDO: Back + Logo
            HStack(spacing: AppTheme.Spacing.s) {
                // BOTÓN DE RETROCESO (condicional)
                if configuration.showBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 18, weight: .medium))  // 18px medium
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 40, height: 40)  // Área de toque: 40x40px
                    .background(Color.white.opacity(0.001))  // Invisible pero táctil
                }

                // LOGO DE PONSIV (siempre visible, navega al feed)
                Button(action: onLogoTap) {
                    RemoteImageView(url: assetService.url(for: "logos/Ponsiv.png"), contentMode: .fit)
                        .frame(width: 300, height: 120)  // Tamaño más grande: 300x120px
                        .padding(.leading, -85)   // Aumentar mueve logo hacia DERECHA
                        .padding(.trailing, 0)  // Aumentar mueve logo hacia IZQUIERDA
                        .padding(.top, 65)       // Aumentar mueve logo hacia ABAJO
                        .padding(.bottom, 0)    // Aumentar mueve logo hacia ARRIBA
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)  // Alineado a la izquierda

            // LADO DERECHO: Acciones contextuales
            HStack(spacing: AppTheme.Spacing.s) {
                // BOTÓN PRINCIPAL DERECHO (condicional: Crear Look o Mensajes)
                if configuration.showsCreateLookAction {
                    // CREAR LOOK: Solo visible en tab de Looks
                    Button(action: onCreateLook) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24, weight: .semibold))  // 24px semibold
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                    .buttonStyle(.plain)
                } else {
                    // MENSAJES: Visible en la mayoría de tabs
                    Button(action: onMessages) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 22, weight: .regular))   // 22px regular
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .padding(.leading, 0)   // Aumentar mueve icono hacia DERECHA
                            .padding(.trailing, 0)  // Aumentar mueve icono hacia IZQUIERDA
                            .padding(.top, 65)       // Aumentar mueve icono hacia ABAJO
                            .padding(.bottom, 0)    // Aumentar mueve icono hacia ARRIBA
                    }
                    .buttonStyle(.plain)
                }

                // MENÚ DE PERFIL (condicional: solo en tab Profile)
                if configuration.showsProfileMenu {
                    Button(action: onShowMenu) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24, weight: .regular))   // 24px regular
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 24)  // Altura fija para alineación consistente
        }
        // PADDING DEL CONTENIDO
        .padding(.horizontal, AppTheme.Spacing.s)  // Padding horizontal large del tema
        .padding(.bottom, AppTheme.Spacing.l)      // Padding inferior medium del tema para bajar los elementos
    }
}
