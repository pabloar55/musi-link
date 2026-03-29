# 🔍 Auditoría de Malas Prácticas — MusiLink

## Nota Global: 6.5 / 10

> [!IMPORTANT]
> Un **6.5** no es una mala nota para un proyecto en desarrollo activo. La arquitectura base es sólida (Riverpod + DI + servicios separados), pero hay deuda técnica acumulada y patrones que frenarían el escalado a producción.

---

## ✅ Lo que está bien hecho (puntos a favor)

| Aspecto | Detalle |
|---------|---------|
| **DI con Riverpod** | Firebase Auth, Firestore y GoogleSignIn se inyectan vía providers globales. Los servicios reciben sus dependencias por constructor → mockeable y testeable. |
| **Separación de capas** | `models/`, `services/`, `providers/`, `screens/`, `widgets/` bien separados; sin lógica de negocio en la UI salvo excepciones. |
| **Firestore Rules** | Reglas granulares con validación de participantes, `affectedKeys()` para limitar campos, y protección de subcolecciones. |
| **Tests unitarios** | 5 test files de servicios + 4 de widgets, con mocks centralizados en `test/helpers/mocks.dart`. Buena base. |
| **Internacionalización** | l10n completo con `AppLocalizations`, sin strings hardcodeados en la UI. |
| **Seguridad de tokens** | `FlutterSecureStorage` para guardar credenciales de Spotify; `.env` en `.gitignore`. |
| **CI/CD** | Pipeline con `flutter analyze` + tests + coverage report. |
| **Error handling en streams** | `.handleError()` en streams de Firestore y manejo de `snapshot.hasError` en StreamBuilders. |

---

## 🔴 Malas prácticas encontradas

### 1. **CRÍTICO — `.env` se incluye en los assets del bundle**
**Archivo:** [pubspec.yaml](file:///c:/Users/pablo/projects/musi_link/pubspec.yaml#L53)

```yaml
assets:
  - assets/images/
  - .env   # ← ESTE ES EL PROBLEMA
```

El `.env` está en `.gitignore` (bien), pero se empaqueta en el APK/IPA como asset. Cualquiera puede descompilar el bundle y leer el `SPOTIFY_CLIENT_ID`. El `client_id` de una app pública de Spotify no es secreto per se (PKCE lo compensa), pero **el patrón es peligroso**: si mañana añades un API key real, se filtrará.

> [!CAUTION]
> **Severidad: Alta.** Cualquier secreto futuro quedaría expuesto. Usar `flutter_dotenv` para cargar `.env` como asset lo expone al usuario final.

---

### 2. **CRÍTICO — `analysis_options.yaml` vacío / mínimo**
**Archivo:** [analysis_options.yaml](file:///c:/Users/pablo/projects/musi_link/analysis_options.yaml)

```yaml
include: package:flutter_lints/flutter.yaml
```

Solo usa el paquete base. Faltan reglas importantes:
- `prefer_const_constructors` 
- `always_use_package_imports`
- `avoid_print` (usas `debugPrint` — bien, pero no hay regla que lo fuerce)
- `unawaited_futures`
- `prefer_final_locals`
- Ninguna sección `linter: rules:` personalizada

> [!WARNING]
> **Severidad: Media.** Sin reglas estrictas, nada impide que alguien añada `print()` en producción o cree código inconsistente.

---

### 3. **ALTO — `providers.dart` es un God File de 214 líneas**
**Archivo:** [providers.dart](file:///c:/Users/pablo/projects/musi_link/lib/providers/providers.dart)

Todo está en un solo archivo: providers de Firebase, servicios, tema, router, rutas de GoRouter y builder de pantallas. Este archivo:
- Importa **13 módulos** (screens, models, services, router)
- Define **lógica de routing** (redirect, routes) que debería estar separada
- Contiene la clase `ThemeModeNotifier` — lógica de negocio mezclada con definiciones de providers
- Tiene `isDarkProvider` duplicando lógica de `ThemeModeNotifier.isDark`

```
providers.dart (214 líneas)
├── Firebase providers (27-37)
├── Service providers (41-89)
├── ThemeModeNotifier class (93-108)
├── Theme providers (110-122)
├── Router notifier provider (126-130)
└── GoRouter con TODAS las rutas (132-213)
```

> [!WARNING]
> **Severidad: Alta.** Imposible reusar, difícil de navegar, y el router debería vivir en `router/`. Si añades 5 rutas más, este archivo será inmantenible.

---

### 4. **ALTO — Modelos sin `Equatable` / `==` / `hashCode`**

Ningún modelo (`AppUser`, `Track`, `Chat`, `Message`, `FriendRequest`, `Artist`, `Genre`, `DiscoveryResult`) implementa `==` ni `hashCode`.

Consecuencias:
- Riverpod y Flutter **no pueden detectar** si un valor ha cambiado realmente
- `Set.intersection()` en el cálculo de compatibilidad compara por identidad, no por valor (funciona aquí porque son `String`, pero es un patrón peligroso si cambias a objetos)
- `copyWith()` genera instancias que `==` dirá que son diferentes aunque sean idénticas

> [!WARNING]
> **Severidad: Media-Alta.** Usar `Equatable` o `freezed` en los modelos es práctica estándar en Flutter.

---

### 5. **ALTO — `UserProfileScreen` pasa un `AppUser` completo via `state.extra`**
**Archivo:** [providers.dart L178-185](file:///c:/Users/pablo/projects/musi_link/lib/providers/providers.dart#L178-L185)

```dart
GoRoute(
  path: '/profile',
  redirect: (context, state) {
    if (state.extra is! AppUser) return '/';
    return null;
  },
  builder: (context, state) =>
      UserProfileScreen(user: state.extra as AppUser),
),
```

Problemas:
- **Deep links rotos**: si alguien abre `musilink://profile`, el `extra` es `null` → redirect a `/`
- **Estado stale**: el `AppUser` pasado es un snapshot; `nowPlaying`, `dailySong`, `friends` pueden estar desactualizados cuando el usuario llega
- **No serializable**: GoRouter no puede restaurar `extra` en hot restart o state restoration

Lo mismo aplica a `/chat` con `Map<String, String>`.

> [!WARNING]
> **Severidad: Alta.** Usar path/query params (`/profile/:uid`) y cargar datos en la pantalla es mucho más robusto.

---

### 6. **MEDIO — `getOrCreateChat` hace un full-table-scan**
**Archivo:** [chat_service.dart L31-43](file:///c:/Users/pablo/projects/musi_link/lib/services/chat_service.dart#L31-L43)

```dart
final existing = await _chatsRef
    .where('participants', arrayContains: _currentUid)
    .get();

for (final doc in existing.docs) {
  final participants = List<String>.from(doc['participants'] ?? []);
  if (participants.contains(otherUid)) { ... }
}
```

Descarga **TODOS** los chats del usuario actual y los itera en memoria. Con 500 chats esto es lento y costoso ($).

> [!TIP]
> **Fix:** Crear un campo `participantsKey` = `[uid1, uid2].sorted().join('_')` e indexar por ese campo. Una query directa con `where('participantsKey', isEqualTo: ...)` es O(1).

---

### 7. **MEDIO — `deleteChat` no maneja paginación de subcolecciones**
**Archivo:** [chat_service.dart L77-92](file:///c:/Users/pablo/projects/musi_link/lib/services/chat_service.dart#L77-L92)

```dart
final messages = await _chatsRef.doc(chatId).collection('messages').get();
final batch = _firestore.batch();
for (final doc in messages.docs) {
  batch.delete(doc.reference);
}
```

- Un `WriteBatch` soporta **máximo 500 operaciones**. Si un chat tiene 600+ mensajes, crashea.
- `collection.get()` descarga TODOS los mensajes a memoria. Esto debería hacerse en una Cloud Function.

---

### 8. **MEDIO — Duplicación masiva del mapeo Spotify → modelo**
**Archivos:** [spotify_service.dart L92-119](file:///c:/Users/pablo/projects/musi_link/lib/services/spotify_service.dart#L92-L119), [spotify_stats_service.dart L30-50](file:///c:/Users/pablo/projects/musi_link/lib/services/spotify_stats_service.dart#L30-L50)

La conversión de `Track` (paquete spotify) → `app.Track` (modelo local) se repite **3 veces** casi idéntica:
1. `SpotifyService.getCurrentlyPlayingTrack()` 
2. `SpotifyGetStats.getTopTracks()` 
3. `SpotifyGetStats.searchTracks()` 

Y la conversión de `Artist` → `app.Artist` se repite 1+ veces.

> [!TIP]
> **Fix:** Crear un `TrackMapper.fromSpotify(Track t)` y `ArtistMapper.fromSpotify(Artist a)` en `models/`.

---

### 9. **MEDIO — `_refreshRelationships()` hace N queries secuenciales**
**Archivo:** [user_search_screen.dart L115-122](file:///c:/Users/pablo/projects/musi_link/lib/screens/user_search_screen.dart#L115-L122)

```dart
Future<void> _refreshRelationships() async {
  for (final user in _results) {
    final rel = await ref.read(friendServiceProvider).getRelationship(user.uid);
    ...
  }
}
```

Si hay 20 resultados = 20 queries secuenciales con `await`. Deberían ejecutarse en paralelo con `Future.wait()`.

Lo mismo en `_search()` (L70-74): query secuencial por cada usuario.

---

### 10. **MEDIO — No hay `dispose` de timers ni streams en `SpotifyService`**

`SpotifyService` tiene un `Timer.periodic` (`_nowPlayingTimer`) pero no tiene un `dispose()` propio. Si el `Provider` se recrea (lo cual pasa al hacer sign-out y sign-in sin reiniciar la app), el timer viejo sigue corriendo.

Aunque `startPollingNowPlaying()` llama a `stopPollingNowPlaying()` primero, no hay garantía de que se llame antes de que el provider sea invalidado.

---

### 11. **BAJO — `ThemeModeNotifier` no persiste la preferencia**

```dart
void toggleDarkLight() {
  state = isDark ? ThemeMode.light : ThemeMode.dark;
}
```

El tema se pierde al cerrar la app. Debería guardarse en `SharedPreferences`.

---

### 12. **BAJO — `Artist.fromMap` descarta los géneros**
**Archivo:** [artist.dart L25-29](file:///c:/Users/pablo/projects/musi_link/lib/models/artist.dart#L25-L29)

```dart
factory Artist.fromMap(Map<String, dynamic> map) => Artist(
      name: (map['name'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      genres: [],  // ← Siempre vacío
    );
```

Los géneros se guardan al crear el artista pero se pierden al leerlo de Firestore. Si alguna vez los necesitas en el lado del cliente, no estarán disponibles.

---

### 13. **BAJO — `AppUser.toFirestore()` omite muchos campos**
**Archivo:** [app_user.dart L92-102](file:///c:/Users/pablo/projects/musi_link/lib/models/app_user.dart#L92-L102)

`toFirestore()` solo serializa 7 campos, mientras que el modelo tiene 15+. Campos como `topArtists`, `topGenres`, `friends`, `dailySong`, `nowPlaying` no se serializan. Esto funciona porque se actualizan por separado en los servicios, pero es confuso — un método `toFirestore()` incompleto es un bug esperando a ocurrir.

---

### 14. **BAJO — Track model tiene `fromJson` Y `fromMap` — inconsistencia**
**Archivo:** [track.dart](file:///c:/Users/pablo/projects/musi_link/lib/models/track.dart)

`Track` tiene dos factorías (`fromJson` para API de Spotify, `fromMap` para Firestore), pero `fromJson` parece código legacy que ya no se usa (la conversión real se hace manualmente en `SpotifyGetStats`).

---

### 15. **BAJO — `SplashScreen` accede a `FirebaseAnalytics.instance` directamente**
**Archivo:** [splash_screen.dart L48](file:///c:/Users/pablo/projects/musi_link/lib/screens/splash_screen.dart#L48)

```dart
FirebaseAnalytics.instance.logEvent(name: 'app_open', parameters: null);
```

Rompe el patrón de DI que usas para Auth y Firestore. Debería inyectarse vía un provider para ser consistente y testeable.

---

### 16. **BAJO — `_dataFuture` en `StatsScreen` usa `List<dynamic>`**
**Archivo:** [stats_screen.dart L26](file:///c:/Users/pablo/projects/musi_link/lib/screens/stats_screen.dart#L26)

```dart
late Future<List<dynamic>> _dataFuture;
```

Pierdes type safety. Se podría usar un `sealed class` o una unión tipada.

---

### 17. **BAJO — Sin rate limiting para envío de solicitudes de amistad**

Un usuario puede spammear `sendRequest()` sin ningún throttle del lado del cliente ni validación del lado de Firestore Rules que impida solicitudes duplicadas.

---

## 📊 Resumen de severidades

| Severidad | Cantidad | Ejemplos clave |
|-----------|----------|----------------|
| 🔴 Crítico | 2 | `.env` en assets, `analysis_options` vacío |
| 🟠 Alto | 3 | God file `providers.dart`, sin `==`/`hashCode`, `extra` no serializable |
| 🟡 Medio | 5 | Full scan en `getOrCreateChat`, batch limit, duplicación de mapeos |
| 🟢 Bajo | 7 | Tema no persistido, `fromMap` pierde datos, `dynamic` list |

---

## 🎯 Top 5 acciones prioritarias

| # | Acción | Impacto | Esfuerzo |
|---|--------|---------|----------|
| 1 | **Sacar `.env` de assets** y usar `--dart-define` o Firebase Remote Config para la config de Spotify | 🔴 Seguridad | Bajo |
| 2 | **Dividir `providers.dart`** en `providers/firebase_providers.dart`, `providers/service_providers.dart`, `providers/theme_provider.dart` y mover las rutas a `router/app_router.dart` | 🟠 Mantenibilidad | Medio |
| 3 | **Usar path params** para `/profile/:uid` y `/chat/:chatId` en vez de `state.extra`, cargando datos en la pantalla con un FutureProvider | 🟠 Robustez | Medio |
| 4 | **Añadir `Equatable`** a todos los modelos | 🟠 Correctitud | Bajo |
| 5 | **Reforzar `analysis_options.yaml`** con reglas estrictas | 🟡 Calidad | Bajo |

---

> [!NOTE]
> **Nota final: 6.5/10** — La base arquitectónica es correcta y madura (DI, separación de capas, tests, l10n, Firestore rules). Los problemas son de **deuda técnica acumulada** (God file, modelos sin equals, mapeos duplicados) y **descuidos de producción** (`.env` en bundle, batch limits, full scans). Con las 5 acciones de arriba, subirías fácilmente a un **8/10**.
