# MusiLink

**MusiLink** es una app social de música desarrollada en Flutter que conecta usuarios a través de sus gustos musicales vía Spotify. Los usuarios pueden descubrir personas con gustos compatibles, ver perfiles musicales públicos y chatear en tiempo real.

## Características Principales

- **Descubrimiento Musical:** Encuentra personas afines gracias a un algoritmo de compatibilidad basado en artistas y géneros compartidos.
- **Perfil Musical Sincronizado:** Visualiza tus artistas, géneros y canciones favoritas directamente desde tu cuenta de Spotify.
- **"Escuchando Ahora" (Now Playing):** Mira en tiempo real qué canción están escuchando tus amigos.
- **Canción del Día (Daily Song):** Selecciona una pista diaria para compartir con tus amigos en el feed de descubrimiento.
- **Chat en Tiempo Real:** Comunícate con otras personas mediante mensajes gestionados por Firestore.
- **Gestión de Amistades:** Envía, acepta y gestiona solicitudes de amistad.
- **Estadísticas Personales:** Accede a un resumen detallado de tus hábitos de escucha en Spotify con filtros por periodo.

## Tecnologías

- **Framework:** Flutter SDK ^3.10.1 (Dart)
- **Backend:** Firebase (Auth, Firestore, Analytics, Crashlytics)
- **APIs:** Spotify Web API con flujo OAuth PKCE (package `spotify` v0.16.0)
- **Internacionalización:** `flutter_localizations` + `intl` (Soporte nativo EN, ES, FR)
- **Gestión de Estado:** `setState()`, `FutureBuilder`, `StreamBuilder` (Sin dependencias externas complejas)
- **UI/UX:** Material Design 3, soporte nativo de Dark/Light mode, paleta de colores personalizada estilo Spotify.

## Estructura del Proyecto

El proyecto está organizado para mantener una separación clara entre vista y lógica de forma modular:

```text
lib/
├── models/         # Modelos de datos (User, Artist, Chat, Message, Track...)
├── screens/        # Vistas principales (Discover, Chat, Profile, Settings...)
├── services/       # Lógica de negocio en Singletons (Auth, Spotify, Firebase...)
├── widgets/        # Componentes UI segmentados por módulos (Discover, Chat, Friends...)
├── theme/          # Configuración de tipografía, temas claro y oscuro
├── utils/          # Almacenamiento seguro, cache de datos rápidos
└── l10n/           # Archivos de traducciones (.arb)
```

## Algoritmo de Compatibilidad

El porcentaje de afinidad musical (Rango 0-100) calcula la compatibilidad entre dos usuarios en función de coincidencias exactas:
- **Artistas Comunes:** Aportan el 70% del valor total (hasta un máximo de 5 artistas compartidos, otorgando 14 puntos cada uno).
- **Géneros Comunes:** Aportan el 30% restante (hasta un máximo de 5 géneros compartidos, otorgando 6 puntos cada uno).

## Privacidad y Seguridad

Las **Reglas de Seguridad de Firestore** se mantienen rigurosas para garantizar la privacidad:
- Los usuarios pueden leer perfiles ajenos pero la modificación se limita únicamente al dueño en su propio documento de la colección `users`.
- Las conversaciones (`chats` y `messages`) están estrictamente bloqueadas para que únicamente los dos participantes tengan acceso a la lectura y escritura.
- Las solicitudes de amistad permiten lectura pública pero se limitan a los involucrados al modificar o eliminarlas.

---

*Desarrollado con ♥ usando Flutter.*
