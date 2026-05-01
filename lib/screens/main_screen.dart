import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/utils/notification_navigation.dart';
import 'package:musi_link/widgets/user_avatar_button.dart';
import 'package:musi_link/screens/discover_screen.dart';
import 'package:musi_link/screens/messages_screen.dart';
import 'package:musi_link/screens/stats_screen.dart';
import 'package:musi_link/screens/friends_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  int currentPageIndex = 0;
  final PageController _pageController = PageController();
  final List<Widget> screens = [
    const DiscoverScreen(),
    const StatsScreen(),
    const MessagesScreen(),
    const FriendsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize FCM: permisos, token, canal Android, listeners
    ref.read(notificationServiceProvider).initialize();
    // FCM: app abierta desde notificación en background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (!mounted) return;
      handleNotificationNavigation(message.data, context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // FCM: tap en local notification (foreground) o cold-start
    ref.listen<Map<String, dynamic>?>(pendingNotificationProvider, (_, data) {
      if (data != null) {
        handleNotificationNavigation(data, context);
        ref.read(pendingNotificationProvider.notifier).setValue(null);
      }
    });

    final unreadChats = ref.watch(unreadChatsCountProvider);
    final pendingCount = ref.watch(receivedRequestsProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => 0,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Image.asset('assets/images/logo.png', width: 150),
        actions: const [UserAvatarButton()],
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        children: screens,
      ),

      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: const Icon(LucideIcons.compass500), label: l10n.navDiscover),
          NavigationDestination(icon: const Icon(LucideIcons.chartNoAxesColumn600), label: l10n.navStats),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadChats > 0,
              label: unreadChats > 9 ? const Text('9+') : Text('$unreadChats'),
              child: const Icon(LucideIcons.messageCircle500),
            ),
            label: l10n.navMessages,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: pendingCount > 9 ? const Text('9+') : Text('$pendingCount'),
              child: const Icon(LucideIcons.users500),
            ),
            label: l10n.navFriends,
          ),
        ],
        selectedIndex: currentPageIndex,

        onDestinationSelected: (int index) {
          _pageController.jumpToPage(index);
          setState(() {
            currentPageIndex = index;
          });
        },
      ),
    );
  }
}
