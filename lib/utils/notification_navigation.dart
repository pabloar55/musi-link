import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      context.go('/');
  }
}
