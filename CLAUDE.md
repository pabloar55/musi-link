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
- **Backend:** Firebase Auth + Cloud Firestore + Analytics + Crashlytics
- **Spotify:** OAuth PKCE flow, top tracks/artists sync, now-playing polling
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
| Utils | `lib/utils/` | Firestore collection constants, Crashlytics reporter, token storage |

### Navigation flow

Auth state drives routing:

`splash → auth → spotify-connect → onboarding → main (Discover / Chat / Friends)`

`AppRouterNotifier` listens to `FirebaseAuth.authStateChanges()` and redirects based on whether the user is logged in, has connected Spotify, and has completed onboarding.

### Discovery algorithm

Compatibility score (0–100):
- **70%** from up to 5 shared artists (14 pts each)
- **30%** from up to 5 shared genres (6 pts each)

Results are paginated (20/page) and cached for 5 minutes in `MusicProfileService`.

### Firestore collections

Defined as constants in `lib/utils/firestore_collections.dart`:
- `users` — profiles with `topArtists`, `topGenres`, Spotify metadata
- `chats` — two-participant rooms
- `messages` — subcollection of `chats`
- `friend_requests` — pending/accepted requests

### Key patterns
- Services are pure Dart classes instantiated as Riverpod `Provider`s; screens call them via `ref.read(xyzServiceProvider)`.
- Real-time data (friends list, chats) uses `StreamProvider` backed by Firestore streams.
- Spotify now-playing uses `Timer.periodic` with explicit cancellation on dispose.
- Friend acceptance uses a Firestore transaction to avoid race conditions.
- Non-fatal errors are always routed through `ErrorReporter` (Crashlytics), never `print()`.
- Use `debugPrint()` instead of `print()` — the linter enforces this.