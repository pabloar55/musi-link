import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/core/chat_service.dart';
import 'package:musi_link/core/models/app_user.dart';
import 'package:musi_link/core/models/chat.dart';
import 'package:musi_link/core/user_service.dart';
import 'package:musi_link/screens/chat_screen.dart';
import 'package:musi_link/screens/user_search_screen.dart';

/// Pantalla social: lista de conversaciones del usuario.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

  /// Obtiene el UID del otro participante del chat.
  String _otherUid(Chat chat) {
    return chat.participants.firstWhere(
      (uid) => uid != _currentUid,
      orElse: () => '',
    );
  }

  /// Formatea la hora del último mensaje.
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: StreamBuilder<List<Chat>>(
        stream: ChatService.instance.getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('❌ Error en stream de chats: ${snapshot.error}');
            return Center(
              child: Text(
                'Error al cargar conversaciones',
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
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: colorScheme.onSurface.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes conversaciones aún',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(150),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Busca usuarios para empezar a chatear',
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
            separatorBuilder: (_, _) =>
                Divider(height: 1, indent: 72, color: colorScheme.onSurface.withAlpha(30)),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUid = _otherUid(chat);

              return FutureBuilder<AppUser?>(
                future: UserService.instance.getUser(otherUid),
                builder: (context, userSnap) {
                  final otherUser = userSnap.data;
                  final name = otherUser?.displayName ?? 'Usuario';
                  final photoUrl = otherUser?.photoUrl ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
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
                      _formatTime(chat.lastMessageTime),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UserSearchScreen()),
          );
        },
        child: const Icon(Icons.person_search),
      ),
    );
  }
}
