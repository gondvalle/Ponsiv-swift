# Ponsiv Expo

React Native + Expo reimplementation of the Ponsiv demo app.

## Inicio

```bash
npm install
```

## Requisitos

- Node >= 20.19.4
- npm 9/10/11
- Expo CLI (vía `npx expo`)
- Android Studio o Xcode si quieres usar emuladores

Notas SDK 54:
- Edge‑to‑edge en Android viene activado por defecto.
- Predictive back permanece desactivado (dejado explícito en `app.json`).
- Reanimated v4 requiere `react-native-worklets`. Ya configurado en `babel.config.js`.
- `expo-file-system`: si tu código usa API antigua, importa temporalmente desde `expo-file-system/legacy`. Este repo ya lo hace en `app/(tabs)/profile.tsx` con un TODO para migrar antes de SDK 55.

## Desarrollo

```bash
npm i
npm run start   # inicia Expo (pulsa "w" para Web)
```

Iniciar directamente en Web (puerto libre):

```bash
npx expo start --web -p 5173
```

Exportar Web estático y servirlo localmente:

```bash
npx expo export -p web
npx http-server dist -p 8080 -c-1
```

### Scripts útiles
- `npm run clean` — ejecuta `limpia todo`
- `npm run assets` — actualiza `src/data/assetsIndex.ts` con los ficheros de `assets`
- `npm run typecheck` — ejecuta `tsc --noEmit`

Estructura principal del proyecto:

```
/app      Rutas con expo-router
/assets   Imágenes, iconos y datos JSON
/src      Componentes, tienda Zustand y utilidades
```

**Nota:** Tras añadir o editar archivos en `assets`, ejecutar `npm run assets` para regenerar el índice estático de recursos.

## Cambios de migración a SDK 54

- Dependencias alineadas con SDK 54 (`npx expo install --fix` + `npx expo-doctor`).
- `expo/metro-config` usado en `metro.config.js` (ya no se instala `@expo/metro-config`).
- Rutas: el grupo `(tabs)` es pathless; navegación actualizada a `/feed` en vez de `/(tabs)/feed`.
- `babel.config.js`: plugin `react-native-worklets/plugin` (Reanimated v4).
- `app.json`: se añadió `android.predictiveBackGestureEnabled: false`.

## Comprobaciones

1. `npx expo-doctor@latest` → sin errores bloqueantes.
2. Web funciona en `/feed`. Si ves pantalla en blanco, revisa rutas que no incluyan el grupo `(tabs)` en el path.
3. Para nativo, genera una dev build nueva si usas `expo-dev-client`.

