import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../main.dart';
import '../models/chat_message.dart';
import '../services/app_state.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const ChatScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<ChatMessage> _messages = [];
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connectWebSocket();
  }

  Future<void> _loadHistory() async {
    try {
      _messages = await _chatService.getChatHistory(widget.eventId);
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _connectWebSocket() async {
    final token = await ApiClient().getToken();
    if (token == null) return;

    final url = _chatService.getWebSocketUrl(widget.eventId, token);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _subscription = _channel!.stream.listen(
        (data) {
          final json = jsonDecode(data);
          final msg = ChatMessage.fromJson(json);
          if (mounted) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          }
        },
        onError: (_) {},
        onDone: () {},
      );
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _channel == null) return;
    _channel!.sink.add(jsonEncode({'text': text}));
    _msgCtrl.clear();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.read<AppState>().currentUser;
    final currentUserId = currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventTitle, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text('No messages yet',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _buildMessage(_messages[i], currentUserId, theme),
                      ),
          ),
          _buildInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessage(
      ChatMessage msg, String currentUserId, ThemeData theme) {
    final isMe = msg.userId == currentUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe ? kGradientPurplePink : null,
          color: isMe ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(msg.userName,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            Text(msg.text,
                style: TextStyle(
                    color: isMe ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: const BoxDecoration(
              gradient: kGradientPurplePink,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _send,
            ),
          ),
        ],
      ),
    );
  }
}
