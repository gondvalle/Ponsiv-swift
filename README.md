# Ponsiv

Este repositorio contiene la aplicación nativa de Ponsiv implementada con SwiftUI y Swift Package Manager. La antigua versión Expo/React Native se ha retirado; puedes consultarla en el historial de Git si necesitas referencias.

## SwiftUI (SPM)

Requisitos:

- Xcode 15.4 o superior (Swift 5.10, iOS 17 SDK)
- macOS 13+

Comandos principales:

```bash
swift build -c release
swift test --parallel
open Package.swift
open Ponsiv.xcodeproj
```

### Build & Run (iOS 26)
```bash
./Scripts/bootstrap.sh
open Ponsiv.xcodeproj
# Xcode: esquema "Ponsiv" → ⌘B → ⌘R
```

Requisitos: Xcode 26 (SDK iOS 26), macOS 26 compatible.

Verificación completa (genera índice de assets, compila y ejecuta tests):

```bash
./Scripts/verify.sh
```

El paquete se estructura en targets modulares:

| Target            | Descripción                                                   |
| ----------------- | ------------------------------------------------------------- |
| `Core`            | Modelos `Codable`, protocolos de repositorio y utilidades     |
| `Infrastructure`  | Persistencia (`PonsivDataStore`), acceso a assets y servicios |
| `Features`        | Estado `ObservableObject` y escenas de la app                 |
| `UIComponents`    | Vistas SwiftUI reutilizables (slides, imágenes remotas, etc.) |
| `App`             | Punto de entrada `@main`, `NavigationStack` + `TabView`       |

## Assets

La carpeta `assets/` del repositorio sigue siendo la fuente de imágenes, logos y datos (`info.json`) utilizados por la app. El script `Scripts/asset-index.swift` genera `Sources/Infrastructure/Assets/Assets.swift` mapeando todos los archivos disponibles. El runtime resuelve rutas mediante `AssetLocator`, que busca los recursos en el bundle y, en su defecto, en `./assets/`.

Cuando añadas o modifiques recursos en `assets/`, ejecuta:

```bash
./Scripts/asset-index.swift
```

## Scripts útiles

- `Scripts/asset-index.swift` — Regenera el índice tipado de assets.
- `Scripts/verify.sh` — Muestra la versión de Swift, regenera el índice y ejecuta build + tests.

## Notas de migración

### Proyecto iOS Xcode

- `Ponsiv.xcodeproj` incluye un target iOS con bundle `com.tuorg.ponsiv` y firma automática.
- El app icon reutiliza `assets/logos/Ponsiv.png`.
- El esquema `Ponsiv` enlaza la librería `PonsivUI` del paquete local.
- Abre el proyecto con `open Ponsiv.xcodeproj`, selecciona el esquema **Ponsiv** y el simulador *iPhone 15 Pro*, compila (`⌘B`) y ejecuta (`⌘R`).

Los detalles de la migración desde Expo/React Native y las decisiones de diseño están documentados en `MIGRATION_NOTES.md`.
