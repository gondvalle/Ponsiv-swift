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
```

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

Los detalles de la migración desde Expo/React Native y las decisiones de diseño están documentados en `MIGRATION_NOTES.md`.
