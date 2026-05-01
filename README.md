# MusiLink

**MusiLink** es una app social de música desarrollada en Flutter que conecta usuarios a través de sus gustos musicales. Los usuarios pueden descubrir personas con gustos compatibles, ver perfiles musicales públicos, chatear en tiempo real y compartir canciones con sus amigos.

## Características Principales

- **Descubrimiento Musical:** Encuentra personas afines gracias a un algoritmo de compatibilidad basado en artistas y géneros compartidos.
- **Perfil Musical:** Visualiza y edita tus artistas y géneros favoritos en tu perfil público.
- **Canción del Día:** Selecciona una pista diaria para compartir con tus amigos en el feed de descubrimiento.
- **Chat en Tiempo Real:** Comunícate con otras personas mediante mensajes gestionados por Firestore. Puedes compartir canciones directamente en el chat.
- **Gestión de Amistades:** Envía, acepta y gestiona solicitudes de amistad.
- **Búsqueda de Canciones y Artistas:** Busca en el catálogo de Spotify para enriquecer tu perfil y compartir música, sin necesidad de vincular tu cuenta de Spotify.
- **Notificaciones Push:** Recibe alertas de mensajes y solicitudes de amistad en tiempo real vía FCM.

## Tecnologías

- **Framework:** Flutter SDK ^3.11.5 (Dart)
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, Storage, Analytics, Crashlytics, FCM)
- **Búsqueda musical:** Catálogo de Spotify vía Cloud Functions (sin OAuth de usuario — búsqueda pública únicamente)
- **Internacionalización:** `flutter_localizations` + `intl` (EN, ES, FR)
- **Gestión de Estado:** Riverpod (`flutter_riverpod` ^3.3.1)
- **Navegación:** GoRouter (`go_router` ^17.2.2)
- **UI/UX:** Material Design 3, soporte nativo Dark/Light mode, paleta personalizada estilo Spotify

### Dependencias principales

| Paquete | Versión |
|---|---|
| flutter_riverpod | ^3.3.1 |
| go_router | ^17.2.2 |
| firebase_core | ^4.6.0 |
| firebase_auth | ^6.4.0 |
| cloud_firestore | ^6.3.0 |
| cloud_functions | ^6.2.0 |
| firebase_storage | ^13.3.0 |
| firebase_messaging | ^16.2.0 |
| firebase_crashlytics | ^5.2.0 |
| firebase_analytics | ^12.3.0 |
| flutter_local_notifications | ^21.0.0 |
| google_sign_in | ^7.2.0 |
| cached_network_image | ^3.4.1 |
| image_picker | ^1.2.1 |
| flutter_secure_storage | ^10.0.0 |
| shared_preferences | ^2.5.5 |

## Estructura del Proyecto

El proyecto sigue una arquitectura en capas con separación clara de responsabilidades:

```text
lib/
├── models/       # DTOs inmutables con serialización Firestore (User, Artist, Chat, Message, Track…)
├── services/     # Toda la lógica de negocio, inyectada como providers de Riverpod
├── providers/    # Wiring de Riverpod: singletons de Firebase, instancias de servicios, streams
├── screens/      # Vistas completas (ConsumerWidget / ConsumerStatefulWidget)
├── widgets/      # Componentes UI reutilizables, organizados por feature
├── router/       # AppRouterNotifier (listener de auth) + configuración de GoRouter
├── theme/        # Material 3, paleta Spotify-green, variantes dark/light
├── utils/        # Constantes de colecciones Firestore, ErrorReporter, caché de usuarios, routing de notificaciones
└── l10n/         # Archivos de traducción .arb (EN, ES, FR)
```

### Pantallas

| Pantalla | Descripción |
|---|---|
| `splash_screen` | Pantalla de carga inicial |
| `auth_screen` | Login / Registro (Google Sign-In + Email) |
| `artist_selector_screen` | Selección / edición de artistas favoritos |
| `onboarding_screen` | Flujo de bienvenida para nuevos usuarios |
| `photo_setup_screen` | Configuración de foto de perfil |
| `main_screen` | Hub principal (Discover / Chat / Friends) |
| `discover_screen` | Feed de compatibilidad y canción del día |
| `messages_screen` | Bandeja de conversaciones |
| `chat_screen` | Chat en tiempo real con compartición de canciones |
| `friends_screen` | Lista de amigos y solicitudes pendientes |
| `user_profile_screen` | Perfil público de otro usuario |
| `user_search_screen` | Búsqueda de usuarios |
| `stats_screen` | Estadísticas musicales del perfil |
| `account_settings_screen` | Configuración de cuenta |
| `privacy_policy_screen` | Política de privacidad |

### Cloud Functions (`functions/src/`)

TypeScript desplegadas en `europe-southwest1`. Gestionan dos responsabilidades:

**`index.ts` — Notificaciones push (disparadas por Firestore):**
- `onNewMessage` — notifica al destinatario cuando llega un mensaje nuevo
- `onFriendRequest` — notifica al usuario objetivo ante una nueva solicitud de amistad
- `onFriendRequestAccepted` — notifica al solicitante al aceptar + elimina el documento de solicitud

**`spotify.ts` — Búsqueda en el catálogo de Spotify (funciones callable):**
- `searchSpotifyArtists` — búsqueda de artistas en Spotify a través de Cloud Functions
- `searchSpotifyTracks` — búsqueda de pistas en Spotify a través de Cloud Functions

Las credenciales de Spotify (`SPOTIFY_CLIENT_ID` / `SPOTIFY_CLIENT_SECRET`) se almacenan en Google Secret Manager y nunca en el código fuente. Para configurarlas:

```bash
firebase functions:secrets:set SPOTIFY_CLIENT_ID
firebase functions:secrets:set SPOTIFY_CLIENT_SECRET
```

## Algoritmo de Compatibilidad

El porcentaje de afinidad musical (rango 0–100) combina dos señales para no penalizar perfiles con listas grandes:

- **70%** — similitud de artistas compartidos
- **30%** — similitud de géneros compartidos

Para cada bloque se calcula:

```text
cobertura = coincidencias / min(total_usuario_a, total_usuario_b)
evidencia = min(coincidencias / umbral_de_evidencia, 1)
similitud = max(cobertura, evidencia)
```

Los umbrales actuales son **7 artistas** y **4 géneros**. Así, una coincidencia completa en perfiles pequeños sigue puntuando alto por cobertura, mientras que compartir muchas coincidencias reales también cuenta como una señal fuerte aunque ambos perfiles sean grandes.

Ejemplos:

- 2 de 2 artistas compartidos aportan `70` puntos por cobertura completa.
- 5 artistas compartidos entre perfiles de 15 artistas aportan `50` puntos: `min(5 / 7, 1) * 70`.
- 5 artistas y 2 géneros compartidos aportan `65` puntos: `50` por artistas + `15` por géneros.

Antes de comparar se normalizan nombres con `trim`, lowercase y deduplicado para evitar que mayúsculas, espacios o valores repetidos distorsionen la puntuación.

Los resultados se paginan (20 por página) y se cachean durante 30 minutos en `MusicProfileService`.

## Flujo de Navegación

El estado de autenticación dirige el enrutado:

```
splash → auth → artist-select → onboarding → photo-setup → main
```

Desde `main` se accede a: `UserSearch`, `UserProfile`, `Chat`, `Stats`, `AccountSettings`, `PrivacyPolicy`.

`AppRouterNotifier` escucha `FirebaseAuth.authStateChanges()` y redirige según si el usuario está autenticado y ha completado el onboarding.

## Privacidad y Seguridad

Las **Reglas de Seguridad de Firestore** garantizan la privacidad:

- Los usuarios pueden leer perfiles ajenos, pero solo el propietario puede modificar su propio documento en `users`.
- Las conversaciones (`chats` y `messages`) están bloqueadas para que únicamente los dos participantes tengan acceso.
- Las solicitudes de amistad permiten lectura pública pero restringen la modificación y eliminación a los involucrados.

---

*Desarrollado con Flutter.*
