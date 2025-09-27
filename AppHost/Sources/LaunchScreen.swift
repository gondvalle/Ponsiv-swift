import SwiftUI

/**
 * PANTALLA DE CARGA (LAUNCH SCREEN)
 *
 * Pantalla inicial que se muestra mientras la aplicación se inicializa.
 * Configurada para usar el color de fondo del sistema.
 *
 * DISEÑO Y POSICIONAMIENTO:
 * - ZStack: Apila elementos uno encima del otro
 * - Color(UIColor.systemBackground): Color de fondo adaptatvo (blanco en modo claro, negro en modo oscuro)
 * - ignoresSafeArea(): Ignora áreas seguras para cubrir toda la pantalla
 * - frame: maxWidth/maxHeight .infinity - ocupa toda la pantalla disponible
 *
 * DEPENDENCIAS CRUZADAS:
 * - Referenciada en AppHost/Resources/Info.plist como UILaunchStoryboardName
 * - Se muestra antes de que PonsivApp.swift cargue RootView
 */
struct LaunchScreen: View {
    var body: some View {
        ZStack {
            // Color de fondo adaptativo del sistema (claro/oscuro automático)
            Color(UIColor.systemBackground)
                .ignoresSafeArea()  // Cubre toda la pantalla incluyendo áreas seguras
        }
        // CONFIGURACIÓN DE PANTALLA COMPLETA
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Ocupa toda la pantalla disponible
    }
}

#Preview {
    LaunchScreen()
}