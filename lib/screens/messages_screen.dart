import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/chat.dart';
import 'package:musi_link/utils/user_future_cache.dart';
import 'package:musi_link/widgets/user_circle_avatar.dart';
import 'package:musi_link/screens/chat_screen.dart';

/// Pantalla social: lista de conversaciones del usuario.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with AutomaticKeepAliveClientMixin, UserFutureCache {
  @override
  bool get wantKeepAlive => true;

  late final Stream<List<Chat>> _chatsStream;

  @override
  void initState() {
    super.initState();
    _chatsStream = ChatService.instance.getChats();
  }

  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

  /// Obtiene el UID del otro participante del chat.
  String _otherUid(Chat chat) {
    return chat.participants.firstWhere(
      (uid) => uid != _currentUid,
      orElse: () => '',
    );
  }

  /// Formatea la hora del último mensaje.
  String _formatTime(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return l10n.socialNow;
    if (diff.inHours < 1) return l10n.socialMinutes(diff.inMinutes);
    if (diff.inDays < 1) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return l10n.socialDays(diff.inDays);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: StreamBuilder<List<Chat>>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('❌ Error en stream de chats: ${snapshot.error}');
            return Center(
              child: Text(
                l10n.socialErrorLoading,
                style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
              ),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: colorScheme.onSurface.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.socialNoChats,
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(150),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.socialNoChatsHint,
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(100),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: 72,
              color: colorScheme.onSurface.withAlpha(30),
            ),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUid = _otherUid(chat);

              return FutureBuilder<AppUser?>(
                future: getUserFuture(otherUid),
                builder: (context, userSnap) {
                  final otherUser = userSnap.data;
                  final isLoading =
                      userSnap.connectionState == ConnectionState.waiting &&
                      !userSnap.hasData;
                  final name =
                      otherUser?.displayName ??
                      (isLoading ? l10n.socialLoading : l10n.socialUser);
                  final photoUrl = otherUser?.photoUrl ?? '';

                  return ListTile(
                    leading: UserCircleAvatar(
                      photoUrl: photoUrl,
                      name: name,
                      radius: 24,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                    trailing: Text(
                      _formatTime(chat.lastMessageTime, l10n),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chat.id,
                            otherUserName: name,
                            otherUserId: otherUid,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
