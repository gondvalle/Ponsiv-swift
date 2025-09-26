# Plan de Paridad React → SwiftUI

Este documento resume las acciones necesarias para replicar 1:1 la UX y las utilidades definidas en `codigo_react/`.

## Arquitectura y estado
- [x] Unificar el estado global en `AppViewModel` como equivalente de `useStore`, exponiendo métodos que espejen la API de la tienda Zustand (autenticación, carrito, likes, wardrobe, looks, pedidos, etc.).
- [ ] Añadir view models específicos (`AuthViewModel`, `CartViewModel`, `ExploreViewModel`, `LooksViewModel`, `ProfileViewModel`) que encapsulen la lógica de cada flujo y eviten que las vistas hablen directamente con `AppViewModel`.
- [x] Ajustar `PonsivDataStore` para soportar la lógica de persistencia presente en la app React (prefijos `asset:`, hidratación de imágenes, sincronización web/nativo, políticas de likes/wardrobe/cart).

## Tema y tokens visuales
- [x] Crear `Theme/Theme.swift` con colores, tipografías, espaciados, radios y sombras reutilizables, replicando los valores hardcodeados en React (`#F6F7F9`, `IOS_BG`, etc.).
- [x] Sustituir los hardcodes en las vistas por tokens del tema.

## Componentes compartidos
- [x] Implementar `TopBarView` y `BottomBarView` equivalentes a `TopBar.tsx` y `BottomBar.tsx`, con estados/acciones idénticas (logos, navegación, badge de carrito, modales, logout).
- [x] Portar `CollapsibleHeaderScrollView` a SwiftUI para reutilizarlo en el perfil.
- [x] Añadir un gestor de háptica (`HapticsManager`) que replique `utils/haptics.ts`.

## Pantallas + funcionalidades
1. **Root / Navegación**
   - [x] Reestructurar `RootView` para usar el TopBar y BottomBar personalizados, manejar el placeholder de carga (logo + activity indicator) y ocultar barras en login.

2. **Login**
   - [x] Replicar layout, estados, toggles de contraseña, manejo de errores y copy exacto.

3. **Feed / Detail**
   - [x] Emular el carrusel vertical infinito (`FlatList` con duplicado de chunks), long press que oculta overlays, modal de tallas y botones con háptica.

4. **Explore**
   - [x] Implementar buscador, chips, banner táctil, carrusel de tendencias ordenado por likes, carrusel de categorías con cards.

5. **Looks**
   - [x] Añadir buscador con filtrado en vivo, grid idéntico, trigger de creación desde query `create=1`, apertura de visor con subconjuntos.
   - [x] `LookDetailView`: mismo carrusel vertical, overlay, long press.
   - [x] `LookEditor`: layout nativo que replique botones y alerts.

6. **Cart**
   - [x] Tabla con thumbs, botones +/- circulares, CTA inferior fija, copy idéntico.

7. **Profile**
   - [x] Usar scroll colapsable, avatar editable, métricas, tabs sticky con iconos, secciones Looks/Likes/Armario/Pedidos con estilos y `wardrobeImageFor` equivalente.

8. **Messages**
   - [x] Vista de tarjetas como en React.

## Utilidades / servicios
- [x] Crear equivalentes Swift para `shuffle`, `reorderStart`, `wardrobeImageFor`, `formatPrice`, `formatDate`, validadores de formularios (email/password mínimos), y `sortProductsByLikes`.
- [x] Garantizar que los repositorios aplican políticas de persistencia/caché análogas (AsyncStorage vs SQLite).

## Documentación y pruebas
- [x] Redactar `README_PARIDAD.md` con el mapeo React → Swift, limitaciones y capturas.
- [ ] Actualizar/añadir snapshot tests para las vistas clave (Login, Feed slide, Explore, Looks, Profile tabs, Cart).

## Riesgos / seguimiento
- [x] Validar performance de carruseles (`TabView` rotado vs `ScrollViewReader`).
- [x] Revisar acceso a librería de fotos (iOS) y fallback en macOS.
- [x] Confirmar coherencia de rutas de assets (`AssetIndex`).
