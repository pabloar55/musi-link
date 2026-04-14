import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required void Function(Map<String, dynamic>) onNotificationTapped,
  })  : _messaging = messaging,
        _firestore = firestore,
        _auth = auth,
        _onNotificationTapped = onNotificationTapped;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final void Function(Map<String, dynamic>) _onNotificationTapped;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'musilink_high';
  static const _channelName = 'musi link Notifications';
  static const _pendingClearUidKey = 'pending_fcm_clear_uid';

  Future<void> initialize() async {
    // 1. iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Initialize local notifications plugin
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // 4. Retry any FCM token clear that failed during a previous sign-out.
    await _retryPendingTokenClear();

    // 5. Request permission and save token
    await _requestPermissionAndSaveToken();

    // 6. Auto-refresh token
    _messaging.onTokenRefresh.listen((_) => _saveToken());

    // 7. Foreground message handler
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  Future<void> _requestPermissionAndSaveToken() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
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
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});
  }

  Future<void> clearToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Best-effort: revoke token from FCM. Even if this fails the token
    // will eventually expire; the Firestore cleanup below is what stops
    // immediate notification delivery to a signed-out user.
    try {
      await _messaging.deleteToken();
    } catch (e, stack) {
      await reportError(e, stack);
    }

    await _clearFcmTokenFromFirestore(uid);
  }

  Future<void> _clearFcmTokenFromFirestore(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()});
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingClearUidKey);
    } catch (e, stack) {
      await reportError(e, stack);
      // Queue so initialize() retries on the next app launch.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_pendingClearUidKey, uid);
      } catch (_) {
        // SharedPreferences failure is non-critical; error already reported.
      }
    }
  }

  Future<void> _retryPendingTokenClear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_pendingClearUidKey);
      if (uid == null) return;
      await _clearFcmTokenFromFirestore(uid);
    } catch (_) {
      // Non-critical; will retry on next launch.
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _localNotifications.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _onNotificationTapped(data);
    } catch (e) {
      debugPrint('FCM: invalid notification payload: $e');
    }
  }
}
