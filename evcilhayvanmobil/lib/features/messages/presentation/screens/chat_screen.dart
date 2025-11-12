import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

enum _ChatEntryType { date, message }

class _ChatEntry {
  final _ChatEntryType type;
  final DateTime? date;
  final Message? message;

  _ChatEntry._(this.type, {this.date, this.message});

  factory _ChatEntry.date(DateTime date) => _ChatEntry._(
        _ChatEntryType.date,
        date: date,
      );

  factory _ChatEntry.message(Message message) => _ChatEntry._(
        _ChatEntryType.message,
        message: message,
      );
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  final List<Message> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSending = false;
  bool _showScrollToBottom = false;

  List<_ChatEntry> _buildEntries() {
    final entries = <_ChatEntry>[];
    DateTime? lastDate;

    for (final message in _messages) {
      final createdAt = message.createdAt.toLocal();
      final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (lastDate == null || !_isSameDay(lastDate, messageDate)) {
        entries.add(_ChatEntry.date(messageDate));
        lastDate = messageDate;
      }

      entries.add(_ChatEntry.message(message));
    }

    return entries;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static const List<String> _monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (_isSameDay(today, target)) {
      return 'Bugün';
    }
    if (_isSameDay(today.subtract(const Duration(days: 1)), target)) {
      return 'Dün';
    }

    final month = _monthNames[target.month - 1];
    return '${target.day} $month ${target.year}';
  }

  bool _isFirstMessage(List<_ChatEntry> entries, int index) {
    final current = entries[index];
    if (current.type != _ChatEntryType.message) return false;
    for (var i = index - 1; i >= 0; i--) {
      final previous = entries[i];
      if (previous.type == _ChatEntryType.date) {
        return true;
      }
      if (previous.type == _ChatEntryType.message) {
        return previous.message!.sender.id != current.message!.sender.id;
      }
    }
    return true;
  }

  void _showInfoSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sohbeti sil'),
        content: const Text(
          'Bu sohbeti kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(messageRepositoryProvider).deleteConversation(
            widget.conversationId,
          );
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showInfoSnack('Sohbet silinemedi: $e');
    }
  }

  void _showConversationActions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('Sohbeti yenile'),
                  onTap: () {
                    Navigator.pop(context);
                    _fetchMessages();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Bildirim tercihleri'),
                  subtitle: const Text('Ayarlar > Bildirimler bölümünden yönetebilirsin'),
                  onTap: () {
                    Navigator.pop(context);
                    _showInfoSnack('Bildirim tercihlerini ayarlar ekranından düzenleyebilirsin.');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Sohbeti listeden sil'),
                  subtitle: const Text('Sohbetler ekranından da silebilirsin.'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteConversation();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onAttachmentTap() {
    _showInfoSnack('Medya paylaşımı yakında eklenecek.');
  }

  void _onEmojiTap() {
    _showInfoSnack('Emoji klavyesi üzerinde çalışıyoruz.');
  }

  Widget _buildComposer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.colorScheme.surface.withOpacity(0.92),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _onAttachmentTap,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            IconButton(
              onPressed: _onEmojiTap,
              icon: const Icon(Icons.emoji_emotions_outlined),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _inputFocusNode,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Mesajını yaz...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppPalette.accentGradient),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollPosition);
    _initialiseChat();
  }

  void _handleScrollPosition() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    final shouldShow = _scrollController.offset < threshold;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
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
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(fetched);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
    _inputFocusNode.requestFocus();

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
    _scrollController.removeListener(_handleScrollPosition);
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider);
    final entries = _buildEntries();

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton.small(
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward_rounded),
            )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.18),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
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
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Eşleşme sonrası sohbet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: _showConversationActions,
          ),
        ],
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
                          : entries.isEmpty
                              ? const _EmptyChatState()
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 12, 12, 24),
                                  itemCount: entries.length,
                                  itemBuilder: (context, index) {
                                    final entry = entries[index];
                                    if (entry.type == _ChatEntryType.date) {
                                      return _DateSeparator(
                                        label: _formatDateLabel(entry.date!),
                                      );
                                    }
                                    final message = entry.message!;
                                    final isMine =
                                        message.sender.id == currentUser?.id;
                                    final isFirstInGroup =
                                        _isFirstMessage(entries, index);
                                    return _MessageBubble(
                                      message: message,
                                      isMine: isMine,
                                      isFirstInGroup: isFirstInGroup,
                                    );
                                  },
                                ),
                ),
              ),
              _buildComposer(theme),
            ],
          ),
        ),
      ),
    );
  }

}

class _DateSeparator extends StatelessWidget {
  final String label;

  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outline.withOpacity(0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor, thickness: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: dividerColor, thickness: 1)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool isFirstInGroup;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isFirstInGroup,
  });

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
    final topMargin = isFirstInGroup ? 12.0 : 4.0;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: () => _copyToClipboard(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          margin: EdgeInsets.fromLTRB(8, topMargin, 8, 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMine ? 18 : (isFirstInGroup ? 20 : 10)),
              topRight: Radius.circular(isMine ? (isFirstInGroup ? 20 : 10) : 18),
              bottomLeft: const Radius.circular(20),
              bottomRight: const Radius.circular(20),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mesaj panoya kopyalandı')),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.colorScheme.surface.withOpacity(0.92),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Henüz mesaj yok',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Eşleşme sonrası ilk mesajını gönder ve sohbeti başlat.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
