// ignore_for_file: subtype_of_sealed_class
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/providers/theme_provider.dart';
import 'package:musi_link/services/auth_service.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/services/friend_service.dart';
import '../helpers/mocks.dart';

class MockChatService extends Mock implements ChatService {}

class MockFriendService extends Mock implements FriendService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Service Providers con overrides', () {
    test('authServiceProvider puede ser sustituido con mock', () {
      final mockAuth = MockAuthService();
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authServiceProvider), same(mockAuth));
    });

    test('providers devuelven mocks cuando se hace override', () {
      final mockUserService = MockUserService();
      final mockChatService = MockChatService();
      final mockFriendService = MockFriendService();

      final container = ProviderContainer(
        overrides: [
          userServiceProvider.overrideWithValue(mockUserService),
          chatServiceProvider.overrideWithValue(mockChatService),
          friendServiceProvider.overrideWithValue(mockFriendService),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(userServiceProvider), same(mockUserService));
      expect(container.read(chatServiceProvider), same(mockChatService));
      expect(container.read(friendServiceProvider), same(mockFriendService));
    });
  });

  group('ThemeModeNotifier', () {
    test('estado inicial es ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('toggleDarkLight alterna entre dark y light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      // system -> isDark es false en tests (platform brightness = light)
      // Así que toggleDarkLight pone dark
      notifier.toggleDarkLight();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // dark -> light
      notifier.toggleDarkLight();
      expect(container.read(themeModeProvider), ThemeMode.light);

      // light -> dark
      notifier.toggleDarkLight();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('isDarkProvider', () {
    test('devuelve false en modo system con platform brightness light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isDarkProvider), false);
    });

    test('devuelve true cuando el tema es dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).toggleDarkLight();
      expect(container.read(isDarkProvider), true);
    });

    test('devuelve false cuando el tema es light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // system -> dark -> light
      container.read(themeModeProvider.notifier).toggleDarkLight();
      container.read(themeModeProvider.notifier).toggleDarkLight();
      expect(container.read(isDarkProvider), false);
    });
  });
}
