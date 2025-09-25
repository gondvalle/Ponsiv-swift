# Notas de migración

## Decisiones clave

- **Persistencia unificada**: se reemplazó la combinación SQLite/AsyncStorage por un único `PonsivDataStore` (actor) que serializa el estado en `Application Support` como JSON. Mantiene las mismas entidades (usuarios, likes, armario, carrito, pedidos y looks) y reutiliza identificadores para conservar la compatibilidad con los assets.
- **Assets tipados**: `Scripts/asset-index.swift` recorre `./assets/` y genera `AssetIndex.swift`; en tiempo de ejecución `AssetLocator` resuelve las rutas apuntando a la carpeta `assets` del bundle o del repositorio. No se duplica contenido en otras ubicaciones.
- **Carga de productos**: `PonsivDataStore` parsea cada `info.json` dentro de `assets/productos/<marca>/<id>/` y construye los modelos `Product` utilizando las imágenes encontradas en `fotos/` y los logos de `assets/logos/`.
- **Arquitectura por capas**: los protocolos viven en `Core`, el almacenamiento en `Infrastructure`, los view models en `Features` y las vistas compartidas en `UIComponents`. El target `App` solo ensambla dependencias y navega.
- **Estado observable**: `AppViewModel` adopta `ObservableObject` y centraliza bootstrap, autenticación, carrito, pedidos y looks.
- **Gestión de fotos**: las imágenes seleccionadas (avatar y looks) se copian al sandbox mediante `PhotoStorage`, almacenando URLs `file://` para su posterior carga.

## Diferencias conocidas

- **Feed vertical**: se implementa mediante `TabView` rotado (paginación vertical). El efecto de reciclado infinito se simplificó; los productos se muestran en un ciclo finito del listado filtrado.
- **Compartir looks**: el flujo abre una `UIActivityViewController` con el título. No se genera un deep-link propio (no existe esquema nativo).
- **Pedidos simulados**: al finalizar la compra se genera un lote de pedidos con estado “En reparto”; se documenta como lógica placeholder.
- **Tamaños en el carrito**: se conserva la talla `M` como predeterminada. Para soportar selección por talla habría que extender el modelo.

## TODO / ideas futuras

- Añadir almacenamiento cifrado para contraseñas (Keychain) y migrar el hash SHA-256 a un almacén seguro.
- Implementar deep links (`SceneDelegate`) para compartir productos/looks como URLs nativas.
- Integrar pruebas snapshot de UI cuando los layouts sean estables.
- Añadir caching en memoria para imágenes externas (`AsyncImage` usa la cache del sistema, pero se puede especializar).
- Extender `verify.sh` para comparar automáticamente el árbol de `assets` y alertar si faltan recursos esperados.
