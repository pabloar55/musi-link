import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/models/message.dart';
import 'package:musi_link/services/user_service.dart';
import 'package:musi_link/widgets/chat/message_bubble.dart';
import 'package:musi_link/widgets/chat/track_bubble.dart';
import 'package:musi_link/widgets/chat/track_search_sheet.dart';
import 'package:musi_link/screens/user_profile_screen.dart';

/// Pantalla de conversación individual.
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService.instance;

  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // Marcar mensajes como leídos al abrir la conversación
    _chatService.markMessagesAsRead(widget.chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await _chatService.sendMessage(widget.chatId, text);

    // Scroll al final tras enviar
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showTrackSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TrackSearchSheet(
        onTrackSelected: (track) async {
          Navigator.of(context).pop();
          await _chatService.sendTrackMessage(widget.chatId, track);
          _scrollToBottom();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
            final navigator = Navigator.of(context);
            final user =
                await UserService.instance.getUser(widget.otherUserId);
            if (user != null && mounted) {
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(user: user),
                ),
              );
            }
          },
          child: Text(widget.otherUserName),
        ),
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.chatSendFirst,
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  );
                }

                // Marcar como leídos cuando llegan nuevos
                _chatService.markMessagesAsRead(widget.chatId);
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _currentUid;

                    if (msg.isTrack) {
                      return TrackBubble(
                        message: msg,
                        isMe: isMe,
                        colorScheme: colorScheme,
                        currentUid: _currentUid,
                        chatId: widget.chatId,
                        chatService: _chatService,
                      );
                    }

                    return MessageBubble(
                      message: msg,
                      isMe: isMe,
                      colorScheme: colorScheme,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _showTrackSearch,
              icon: const Icon(Icons.music_note),
              tooltip: l10n.chatShareSong,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: l10n.chatWriteMessage,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

