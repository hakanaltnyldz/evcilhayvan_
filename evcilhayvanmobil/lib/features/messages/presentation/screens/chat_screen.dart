import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvanmobil/core/socket_service.dart';
import 'package:evcilhayvanmobil/core/theme/app_palette.dart';
import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';
import 'package:evcilhayvanmobil/features/messages/data/repositories/message_repository.dart';
import 'package:evcilhayvanmobil/features/messages/domain/models/message_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String receiverName;
  final String? receiverAvatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverName,
    this.receiverAvatarUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Message> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initialiseChat();
  }

  Future<void> _initialiseChat() async {
    await _fetchMessages();
    await _socketService.connect();
    _socketService.joinRoom(widget.conversationId);

   _socketService.onMessage((data) {
  try {
    final map = Map<String, dynamic>.from(data as Map);
    final incoming = Message.fromJson(map);
    final exists = _messages.any((m) => m.id == incoming.id);
    if (!exists) {
      setState(() => _messages.add(incoming));
      _scrollToBottom();
    }
  } catch (e) {
    debugPrint('⚠️ Gelen mesaj parse edilemedi: $e');
  }
});

  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(messageRepositoryProvider);
      final fetched = await repo.getMessages(widget.conversationId);
      fetched.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      setState(() {
        _messages
          ..clear()
          ..addAll(fetched);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = ref.read(authProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj göndermek için giriş yapmalısınız.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final pendingMessage = Message(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      sender: currentUser,
      text: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(pendingMessage);
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final repo = ref.read(messageRepositoryProvider);
      final saved = await repo.sendMessage(
        conversationId: widget.conversationId,
        text: text,
      );

      setState(() {
        final index =
            _messages.indexWhere((element) => element.id == pendingMessage.id);
        if (index != -1) {
          _messages[index] = saved;
        } else {
          _messages.add(saved);
        }
      });

      // ChatScreen içinde, kaydedilmiş mesaja göre yay:
_socketService.sendMessage(
  conversationId: saved.conversationId,
  message: {
    '_id': saved.id,
    'conversationId': saved.conversationId,
    'text': saved.text,
    'createdAt': saved.createdAt.toIso8601String(),
    'sender': {
      '_id': saved.sender.id,
      'name': saved.sender.name,
      'email': saved.sender.email,
      // avatarUrl gerekiyorsa ekle
    },
  },
);
// ChatScreen içinde, kaydedilmiş mesaja göre yay:
_socketService.sendMessage(
  conversationId: saved.conversationId,
  message: {
    '_id': saved.id,
    'conversationId': saved.conversationId,
    'text': saved.text,
    'createdAt': saved.createdAt.toIso8601String(),
    'sender': {
      '_id': saved.sender.id,
      'name': saved.sender.name,
      'email': saved.sender.email,
      // avatarUrl gerekiyorsa ekle
    },
  },
);

    } catch (e) {
      setState(() {
        _messages.removeWhere((element) => element.id == pendingMessage.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: widget.receiverAvatarUrl != null
                  ? NetworkImage(widget.receiverAvatarUrl!)
                  : null,
              child: widget.receiverAvatarUrl == null
                  ? Text(
                      widget.receiverName.isNotEmpty
                          ? widget.receiverName[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.onPrimary),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.receiverName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Şimdi aktif',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? _ErrorView(
                              message: _errorMessage!,
                              onRetry: _fetchMessages,
                            )
                          : _messages.isEmpty
                              ? const _EmptyChatState()
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    final isMine =
                                        message.sender.id ==
                                            ref.read(authProvider)?.id;
                                    return _MessageBubble(
                                      message: message,
                                      isMine: isMine,
                                    );
                                  },
                                ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surface,
                        AppPalette.background,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Mesaj yaz...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppPalette.accentGradient,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: _isSending ? null : _sendMessage,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  theme.colorScheme.onSurface.withOpacity(0.06),
                            ),
                            icon: _isSending
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: const AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isMine
        ? LinearGradient(colors: AppPalette.accentGradient)
        : LinearGradient(colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceVariant.withOpacity(0.6),
          ]);

    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final textColor =
        isMine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMine ? 16 : 6),
            topRight: Radius.circular(isMine ? 6 : 16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(message.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline,
            size: 60, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Henüz mesaj yok.',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'İlk mesajı göndererek sohbeti başlatın.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Sohbet yüklenemedi',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final hours = time.hour.toString().padLeft(2, '0');
  final minutes = time.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}