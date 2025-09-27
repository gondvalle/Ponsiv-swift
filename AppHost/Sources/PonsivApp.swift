import SwiftUI
import PonsivUI  // Importa el módulo principal de UI - contiene RootView y todos los componentes de interfaz
#if canImport(UIKit)
import UIKit     // Para iOS - necesario para debugging de pantalla y ventanas
#endif

/**
 * ARCHIVO PRINCIPAL DE LA APLICACIÓN
 *
 * Este es el punto de entrada principal de la app Ponsiv. Configura el entorno inicial,
 * inicializa el modelo de aplicación y establece la vista raíz.
 *
 * DEPENDENCIAS CRUZADAS:
 * - Usa PonsivBootstrap.makeEnvironment() del módulo PonsivUI
 * - Inicializa AppViewModel (definido en Sources/Features/Shared/AppViewModel.swift)
 * - Renderiza RootView (definido en Sources/App/RootView.swift)
 *
 * CONFIGURACIÓN DE PANTALLA:
 * - maxWidth/maxHeight: .infinity - ocupa toda la pantalla disponible
 * - alignment: .topLeading - alineación superior izquierda
 * - ignoresSafeArea() - ignora las áreas seguras del dispositivo
 */
@main
struct PonsivApp: App {
    private let environment: AppEnvironment    // Configuración del entorno de la aplicación
    @StateObject private var appModel: AppViewModel  // Modelo principal que maneja el estado global

    /**
     * INICIALIZADOR PRINCIPAL
     * Crea el entorno de configuración y inicializa el modelo de aplicación
     */
    init() {
        let env = PonsivBootstrap.makeEnvironment()  // Configurado en PonsivUI
        self.environment = env
        _appModel = StateObject(wrappedValue: AppViewModel(environment: env))
    }

    /**
     * CONFIGURACIÓN PRINCIPAL DE LA VENTANA
     *
     * DISEÑO Y POSICIONAMIENTO:
     * - frame: maxWidth/maxHeight .infinity - ocupa toda la pantalla disponible
     * - alignment: .topLeading - contenido alineado arriba-izquierda
     * - ignoresSafeArea() - ignora notch, barra de estado, etc.
     *
     * INYECCIÓN DE DEPENDENCIAS:
     * - environmentObject(appModel) - inyecta el modelo global para toda la app
     * - environment(\.appEnvironment) - inyecta configuración del entorno
     *
     * LLAMADAS A OTROS ARCHIVOS:
     * - RootView() está definido en Sources/App/RootView.swift
     * - appModel.bootstrap() inicializa datos desde Sources/Features/Shared/AppViewModel.swift
     */
    var body: some Scene {
        WindowGroup {
            RootView()  // Vista principal definida en Sources/App/RootView.swift
                .environmentObject(appModel)  // Inyecta modelo global para acceso en toda la app
                .environment(\.appEnvironment, environment)  // Inyecta configuración del entorno
                .task {
                    // Auto-inicialización cuando la app se carga por primera vez
                    if appModel.phase == .loading {
                        appModel.bootstrap()  // Método definido en AppViewModel.swift
                    }
                }
                // CONFIGURACIÓN DE PANTALLA COMPLETA
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .ignoresSafeArea()  // Ignora áreas seguras (notch, indicadores home, etc.)

                // DEBUGGING TEMPORAL - Información de configuración y pantalla
                .onAppear {
                    // Debug del Info.plist generado
                    let dict = Bundle.main.infoDictionary ?? [:]
                    print(">>> UILaunchStoryboardName =", dict["UILaunchStoryboardName"] as? String ?? "<none>")
                    print(">>> Bundle path =", Bundle.main.bundlePath)
                    print(">>> All keys =", Array(dict.keys).sorted())

                    // DEBUG: Información detallada de pantalla y ventana (solo iOS)
                    #if canImport(UIKit)
                    DispatchQueue.main.async {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            print("🔍 WINDOW DEBUG:")
                            print("   Window bounds: \(window.bounds)")        // Tamaño de ventana
                            print("   Window frame: \(window.frame)")          // Posición y tamaño
                            print("   Screen bounds: \(window.screen.bounds)") // Tamaño total de pantalla
                            print("   Screen native bounds: \(window.screen.nativeBounds)") // Resolución nativa
                            print("   Screen scale: \(window.screen.scale)")   // Factor de escala (1x, 2x, 3x)
                            print("   Safe area insets: \(window.safeAreaInsets)") // Áreas seguras (notch, etc.)
                        }

                        print("🔍 SCREEN DEBUG:")
                        print("   Main screen bounds: \(UIScreen.main.bounds)")
                        print("   Main screen native bounds: \(UIScreen.main.nativeBounds)")
                        print("   Main screen scale: \(UIScreen.main.scale)")
                    }
                    #endif
                }
        }
    }
}
