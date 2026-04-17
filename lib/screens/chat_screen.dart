import 'dart:async';


import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/models/message.dart';
import 'package:musi_link/widgets/chat/message_bubble.dart';
import 'package:musi_link/widgets/chat/track_bubble.dart';
import 'package:musi_link/widgets/chat/track_search_sheet.dart';
import 'package:musi_link/widgets/skeleton_loader.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de conversación individual.
class ChatScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final Stream<List<Message>> _messagesStream;
  StreamSubscription<List<Message>>? _messagesSubscription;

  // Paginación: lista única de mensajes acumulados.
  List<Message> _allMessages = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  /// UID of the authenticated user from the Riverpod provider.
  /// Returns empty string if session was lost — message bubbles fall back to
  /// always showing "other" side, which is safe for the UI.
  String get _currentUid => ref.read(firebaseAuthProvider).currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _messagesStream = ref.read(chatServiceProvider).getMessages(widget.chatId);

    _messagesSubscription = _messagesStream.listen((streamMessages) {
      if (!mounted) return;
      final isFirst = _isInitialLoading;
      setState(() {
        if (streamMessages.isNotEmpty) {
          // Preservar mensajes más antiguos ya cargados por paginación.
          final oldestStreamTimestamp = streamMessages.first.timestamp;
          final preserved = _allMessages
              .where((m) => m.timestamp.isBefore(oldestStreamTimestamp))
              .toList();
          _allMessages = [...preserved, ...streamMessages];
        } else {
          _allMessages = [];
        }
        _isInitialLoading = false;
        // Si la primera carga tiene menos del límite de página, no hay mensajes más antiguos.
        if (isFirst) {
          _hasMoreMessages = streamMessages.length >= 30;
        }
      });
      if (streamMessages.isNotEmpty) {
        unawaited(ref.read(chatServiceProvider).markMessagesAsRead(widget.chatId));
        _scrollToBottom();
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingMore &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_allMessages.isEmpty) return;
    final cursor = _allMessages.first.timestamp;

    setState(() => _isLoadingMore = true);

    try {
      final older = await ref
          .read(chatServiceProvider)
          .loadOlderMessages(widget.chatId, before: cursor);

      if (!mounted) return;

      if (older.isEmpty) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreMessages = false;
        });
        return;
      }

      // Capturar posición justo antes de modificar la lista para que el
      // delta refleje exactamente cuánto contenido se añade arriba.
      final oldOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
      final oldExtent = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0.0;

      final existingIds = _allMessages.map((m) => m.id).toSet();
      final newMessages =
          older.where((m) => !existingIds.contains(m.id)).toList();

      setState(() {
        _isLoadingMore = false;
        _allMessages = [...newMessages, ..._allMessages];
        if (older.length < 30) _hasMoreMessages = false;
      });

      // Ajustar scroll para que el contenido visible no salte.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final delta = _scrollController.position.maxScrollExtent - oldExtent;
          if (delta > 0) _scrollController.jumpTo(oldOffset + delta);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await ref.read(chatServiceProvider).sendMessage(
      widget.chatId,
      text,
      otherUid: widget.otherUserId,
    );

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
          await ref.read(chatServiceProvider).sendTrackMessage(
            widget.chatId,
            track,
            otherUid: widget.otherUserId,
          );
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
            final nav = GoRouter.of(context);
            final user =
                await ref.read(userServiceProvider).getUser(widget.otherUserId);
            if (user != null && mounted) {
              unawaited(nav.push('/profile', extra: user));
            }
          },
          child: Text(widget.otherUserName),
        ),
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: _buildMessageList(colorScheme, l10n),
          ),
          _buildInputBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageList(ColorScheme colorScheme, AppLocalizations l10n) {
    if (_isInitialLoading) {
      return const SkeletonShimmer(child: SkeletonChatMessages());
    }

    if (_allMessages.isEmpty) {
      return Center(
        child: Text(
          l10n.chatSendFirst,
          style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
        ),
      );
    }

    return Column(
      children: [
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _allMessages.length,
            itemBuilder: (context, index) {
              final msg = _allMessages[index];
              final isMe = msg.senderId == _currentUid;

              if (msg.isTrack) {
                return TrackBubble(
                  message: msg,
                  isMe: isMe,
                  colorScheme: colorScheme,
                  currentUid: _currentUid,
                  chatId: widget.chatId,
                  chatService: ref.read(chatServiceProvider),
                );
              }

              return MessageBubble(
                message: msg,
                isMe: isMe,
                colorScheme: colorScheme,
                currentUid: _currentUid,
                chatId: widget.chatId,
                chatService: ref.read(chatServiceProvider),
              );
            },
          ),
        ),
      ],
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
              icon: const Icon(LucideIcons.music),
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
              icon: const Icon(LucideIcons.sendHorizontal500),
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

