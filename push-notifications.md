# Plan: Push Notifications — musi_link

## Context
Se implementan notificaciones push para tres eventos: nuevo mensaje en chat, nueva solicitud de amistad recibida, y solicitud de amistad aceptada. La arquitectura usa Cloud Functions como disparadores de FCM (Firebase Cloud Messaging) para que las notificaciones lleguen aunque el emisor tenga la app cerrada. El cliente Flutter almacena el token FCM en `users/{uid}.fcmToken` y maneja los tres estados de la app (primer plano, segundo plano, terminada).

---

## Archivos a modificar / crear

| Archivo | Acción |
|---|---|
| `pubspec.yaml` | Agregar 2 paquetes |
| `android/app/src/main/AndroidManifest.xml` | Permiso + meta-data del canal |
| `android/app/src/main/res/values/colors.xml` | **Crear** — color Spotify-green para icono |
| `ios/Runner/Info.plist` | Background modes (remote-notification) |
| `lib/providers/firebase_providers.dart` | Agregar `firebaseMessagingProvider` |
| `lib/services/notification_service.dart` | **Crear** — servicio FCM principal |
| `lib/providers/service_providers.dart` | `notificationServiceProvider` + actualizar `authServiceProvider` |
| `lib/services/auth_service.dart` | `clearToken()` en `signOut()` |
| `lib/main.dart` | Handler background + `onBackgroundMessage` |
| `lib/utils/notification_navigation.dart` | **Crear** — lógica de navegación compartida |
| `lib/screens/main_screen.dart` | `onMessageOpenedApp` listener en `initState` |
| `lib/screens/splash_screen.dart` | `getInitialMessage()` para cold-start |
| `functions/src/index.ts` | **Crear** — 3 Cloud Functions |

---

## Paso 1 — pubspec.yaml

Agregar después de `firebase_crashlytics`:

```yaml
firebase_messaging: ^15.2.5
flutter_local_notifications: ^18.0.1
```

---

## Paso 2 — Android

### `AndroidManifest.xml`

Dentro de `<manifest>` (fuera de `<application>`):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Dentro de `<application>`:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="musilink_high" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

### `android/app/src/main/res/values/colors.xml` (crear)
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#1DB954</color>
</resources>
```

### Icono de notificación
Agregar `android/app/src/main/res/drawable/ic_notification.png` — PNG monochrome 24dp (blanco sobre transparente). Se puede generar a partir del ícono de la app.

---

## Paso 3 — iOS `Info.plist`

Agregar antes del `</dict>` final:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

**Paso manual en Xcode:** Habilitar capability "Push Notifications" en Signing & Capabilities.

---

## Paso 4 — `lib/providers/firebase_providers.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);
```

---

## Paso 5 — `lib/services/notification_service.dart` (nuevo)

```dart
class NotificationService {
  NotificationService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  });

  Future<void> initialize() async {
    // 1. iOS foreground options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
    // 2. Crear canal Android
    const channel = AndroidNotificationChannel(
      'musilink_high', 'musi link Notifications',
      importance: Importance.high, playSound: true,
    );
    await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
    // 3. Init local notifications
    await _localNotifications.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );
    // 4. Permisos + token
    await _requestPermissionAndSaveToken();
    // 5. Renovación automática de token
    _messaging.onTokenRefresh.listen((_) => _saveToken());
    // 6. Handler de foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  Future<void> _requestPermissionAndSaveToken() async {
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _saveToken();
    }
  }

  Future<void> _saveToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<void> clearToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _messaging.deleteToken();
      await _firestore.collection('users').doc(uid)
          .update({'fcmToken': FieldValue.delete()});
    } catch (e, stack) { await reportError(e, stack); }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _localNotifications.show(
      n.hashCode, n.title, n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'musilink_high', 'musi link Notifications',
          importance: Importance.high, priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    // payload es el JSON de message.data; se pasa al router desde MainScreen
    // usando el mismo handleNotificationNavigation de notification_navigation.dart
  }
}
```

---

## Paso 6 — `lib/providers/service_providers.dart`

```dart
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    messaging: ref.read(firebaseMessagingProvider),
    firestore: ref.read(firebaseFirestoreProvider),
    auth: ref.read(firebaseAuthProvider),
  );
});

// Actualizar authServiceProvider para inyectar notificationService:
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(userServiceProvider),
    auth: ref.read(firebaseAuthProvider),
    googleSignIn: ref.read(googleSignInProvider),
    notificationService: ref.read(notificationServiceProvider),
  );
});
```

---

## Paso 7 — `lib/services/auth_service.dart`

Agregar `NotificationService _notificationService` al constructor.

```dart
Future<void> signOut() async {
  await _ensureGoogleInitialized();
  try { await _notificationService.clearToken(); } catch (_) {}
  await _googleSignIn.signOut();
  await _auth.signOut();
}
```

El `clearToken()` va **antes** de `_auth.signOut()` porque necesita `currentUser?.uid`.

---

## Paso 8 — `lib/main.dart`

Top-level (fuera de `main()`):
```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}
```

Dentro de `main()`, después de `Firebase.initializeApp(...)`:
```dart
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

---

## Paso 9 — Navegación desde notificación

### `lib/utils/notification_navigation.dart` (nuevo)

```dart
void handleNotificationNavigation(
  Map<String, dynamic> data,
  BuildContext context,
) {
  final type = data['type'] as String?;
  switch (type) {
    case 'new_message':
      final chatId = data['chatId'] as String?;
      final otherUserName = data['otherUserName'] as String?;
      final otherUserId = data['otherUserId'] as String?;
      if (chatId != null && otherUserName != null && otherUserId != null) {
        context.push(
          '/chat?chatId=$chatId'
          '&otherUserName=${Uri.encodeComponent(otherUserName)}'
          '&otherUserId=$otherUserId',
        );
      }
    case 'friend_request':
    case 'friend_request_accepted':
      context.go('/');  // MainScreen — el usuario navega a la tab de amigos
  }
}
```

### `lib/screens/main_screen.dart` — `initState`

```dart
@override
void initState() {
  super.initState();
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    handleNotificationNavigation(message.data, context);
  });
}
```

### `lib/screens/splash_screen.dart` — cold-start

Al inicio de `_initialize()`:
```dart
final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null && mounted) {
  // Guardar en un Provider temporal o navegar después del redirect
}
```

**Nota:** El cold-start es más complejo porque SplashScreen hace redirect automático. La estrategia: guardar `initialMessage.data` en un `StateProvider<Map?>` global, y consumirlo en MainScreen's `initState` — si hay datos, llamar `handleNotificationNavigation` y limpiar el provider.

---

## Paso 10 — Cloud Functions

### Inicialización
```bash
firebase init functions  # TypeScript, Node 20
```

### `functions/src/index.ts`

**Función 1 — Nuevo mensaje:**
- Trigger: `onDocumentCreated('chats/{chatId}/messages/{messageId}')`
- Lee `senderId` del mensaje → busca el otro `participantId` en `chats/{chatId}`
- Lee `fcmToken` del receptor y `displayName` del emisor
- FCM data payload: `{ type, chatId, otherUserId: senderId, otherUserName: senderName }`

**Función 2 — Nueva solicitud:**
- Trigger: `onDocumentCreated('friend_requests/{requestId}')`
- Lee `receiverId` → `fcmToken`; lee `senderId` → `displayName`
- FCM data payload: `{ type: 'friend_request', senderId }`

**Función 3 — Solicitud aceptada:**
- Trigger: `onDocumentUpdated('friend_requests/{requestId}')`
- Solo actúa si `before.status === 'pending'` && `after.status === 'accepted'`
- Notifica al `senderId` original
- FCM data payload: `{ type: 'friend_request_accepted', accepterId: receiverId }`

**Error handling en las 3 funciones:**
```typescript
catch (error: any) {
  if (error.code === 'messaging/registration-token-not-registered') {
    // Limpiar token inválido de Firestore
    await db.doc(`users/${recipientUid}`).update({ fcmToken: FieldValue.delete() });
  }
}
```

---

## Orden de ejecución

1. `pubspec.yaml` → `flutter pub get`
2. Android config (Manifest + colors.xml + icono)
3. iOS Info.plist + Xcode capability (manual)
4. `firebase_providers.dart` — agregar `firebaseMessagingProvider`
5. `notification_service.dart` — crear
6. `service_providers.dart` — registrar `notificationServiceProvider`, actualizar `authServiceProvider`
7. `auth_service.dart` — `clearToken` en `signOut`
8. `main.dart` — background handler
9. `notification_navigation.dart` — crear; `main_screen.dart` + `splash_screen.dart` — wiring
10. Cloud Functions — `firebase init functions` → implementar → `firebase deploy --only functions`

---

## Verificación

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

**Tests manuales:**
1. Abrir app → verificar que `fcmToken` aparece en Firestore `users/{uid}`
2. Cerrar sesión → verificar que `fcmToken` se elimina
3. Enviar mensaje desde otro usuario → verificar notificación (app en foreground, background y terminada)
4. Enviar solicitud de amistad → verificar notificación en receptor
5. Aceptar solicitud → verificar notificación en emisor original
6. Tocar notificación → verificar navegación correcta
