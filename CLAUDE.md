# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                        # Install dependencies
flutter analyze --no-fatal-infos       # Lint (matches CI)
flutter test                           # Run all tests
flutter test test/path/to_test.dart    # Run a single test file
flutter test --coverage                # Run tests with coverage
flutter run                            # Run on connected device/emulator
flutter build apk                      # Build Android APK
```

> CI requires a `.env` file to exist (`touch .env`) before running analyze or tests.

## Architecture

**musi_link** is a Flutter social music app connecting users via Spotify compatibility.

### Stack
- **State management:** Riverpod (`Provider`, `StreamProvider`, `NotifierProvider`)
- **Navigation:** GoRouter with auth-aware redirect logic (`router/`)
- **Backend:** Firebase Auth + Cloud Firestore + Analytics + Crashlytics + Cloud Messaging (FCM)
- **Cloud Functions:** TypeScript in `functions/src/` (region: `europe-southwest1`) — push notifications (index.ts) + Spotify catalog search (spotify.ts); secrets stored in Google Secret Manager via `defineSecret`
- **Spotify:** Public catalog search (artists, tracks) proxied through Cloud Functions (`searchSpotifyArtists`, `searchSpotifyTracks`); no user OAuth — PKCE flow has been removed
- **Notifications:** `firebase_messaging` + `flutter_local_notifications`; FCM token stored in Firestore user doc; `NotificationService` handles foreground/background/terminated states; `notification_navigation.dart` routes notification taps to the correct screen
- **Auth extras:** `google_sign_in`
- **i18n:** `flutter_localizations` + `intl` — English, Spanish, French (`l10n/`)
- **Testing:** `flutter_test` + `mocktail`

### Layer structure

| Layer | Path | Role |
|---|---|---|
| Models | `lib/models/` | Immutable DTOs with Firestore serialization |
| Services | `lib/services/` | All business logic; injected as Riverpod providers |
| Providers | `lib/providers/` | Riverpod wiring: Firebase singletons, service instances, streams |
| Screens | `lib/screens/` | Full-page views, use `ConsumerWidget`/`ConsumerStatefulWidget` |
| Widgets | `lib/widgets/` | Reusable UI components, organized by feature subdirectory |
| Router | `lib/router/` | `AppRouterNotifier` (auth state listener) + `go_router_provider.dart` |
| Theme | `lib/theme/app_theme.dart` | Material 3, Spotify-green palette, dark/light variants |
| Utils | `lib/utils/` | Firestore collection constants, Crashlytics reporter, token storage, notification routing, user cache |

### Navigation flow

Auth state drives routing:

`splash → auth → spotify-connect → onboarding → main (Discover / Chat / Friends)`

Additional screens reachable from main: `UserSearch`, `UserProfile`, `Stats`, `AccountSettings`, `PrivacyPolicy`.

`AppRouterNotifier` listens to `FirebaseAuth.authStateChanges()` and redirects based on whether the user is logged in, has connected Spotify, and has completed onboarding.

### Discovery algorithm

Compatibility score (0–100):
- **70%** from up to 5 shared artists (14 pts each)
- **30%** from up to 5 shared genres (6 pts each)

Results are paginated (20/page) and cached for 30 minutes in `MusicProfileService`.

### Firestore collections

Defined as constants in `lib/utils/firestore_collections.dart`:
- `users` — profiles with `topArtists`, `topGenres`, Spotify metadata, FCM token
- `chats` — two-participant rooms
- `messages` — subcollection of `chats`
- `friend_requests` — pending/accepted requests

### Cloud Functions (`functions/`)

TypeScript project deployed to `europe-southwest1`. Split across two source files:

**`functions/src/index.ts`** — Firestore-triggered push notifications:
- `onNewMessage` — notifies chat recipient on message creation
- `onFriendRequest` — notifies target user on new friend request
- `onFriendRequestAccepted` — notifies requester on acceptance + deletes the request doc

Each function reads the recipient's FCM token from the `users` collection and sends via Firebase Admin SDK. See `push-notifications.md` at the project root for setup details.

**`functions/src/spotify.ts`** — Callable functions for Spotify catalog search:
- `searchSpotifyArtists` — proxies artist search; requires Firebase Auth
- `searchSpotifyTracks` — proxies track search; requires Firebase Auth

Both use `defineSecret` for `SPOTIFY_CLIENT_ID` / `SPOTIFY_CLIENT_SECRET` (stored in Google Secret Manager — never in source or the binary). A module-level token cache reuses the Client Credentials access token across warm instances. To set secrets: `firebase functions:secrets:set SPOTIFY_CLIENT_ID` / `SPOTIFY_CLIENT_SECRET`.

### Key patterns
- Services are pure Dart classes instantiated as Riverpod `Provider`s; screens call them via `ref.read(xyzServiceProvider)`.
- Real-time data (friends list, chats) uses `StreamProvider` backed by Firestore streams.
- Spotify catalog search goes through `SpotifyCloudService` → Cloud Functions; never call the Spotify API directly from Flutter.
- Friend acceptance uses a Firestore transaction to avoid race conditions.
- Non-fatal errors are always routed through `ErrorReporter` (Crashlytics), never `print()`.
- Use `debugPrint()` instead of `print()` — the linter enforces this.
- FCM tokens are refreshed via `NotificationService.init()` on login and stored in the user's Firestore document; Cloud Functions read this token to send targeted push notifications.