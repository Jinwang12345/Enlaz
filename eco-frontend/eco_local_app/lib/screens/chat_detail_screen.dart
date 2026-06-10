import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../core/theme/app_colors.dart';
import '../providers/user_provider.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String contactId;
  final String contactName;
  final String contactAvatar;

  const ChatDetailScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactAvatar,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  late ChatService _chatService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  Timer? _statusTimer;

  bool _isLoadingHistory = true;
  bool _isContactOnline = false;

  @override
  void initState() {
    super.initState();
    _chatService = ref.read(chatServiceProvider);
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final currentUser = ref.read(userProvider);
    final currentUserId = currentUser?.id ?? 'MI_ID';

    try {
      final history = await _chatService.getHistory(currentUserId, widget.contactId);
      if (mounted) {
        setState(() {
          _messages.addAll(history);
          _isLoadingHistory = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
      }
    } catch (e) {
      debugPrint('Error al cargar historial: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }

    await _loadContactStatus();
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadContactStatus();
    });

    _messageSubscription?.cancel();
    _messageSubscription = _chatService.messageStream.listen((message) {
      final senderId = message['sender_id']?.toString();
      final receiverId = message['receiver_id']?.toString();
      final isForCurrentChat =
          (senderId == currentUserId && receiverId == widget.contactId) ||
          (senderId == widget.contactId && receiverId == currentUserId);

      if (isForCurrentChat && !_messages.any((item) => item['message'] == message['message'] && item['timestamp'] == message['timestamp'])) {
        if (mounted) {
          setState(() => _messages.add(message));
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    });
  }

  Future<void> _loadContactStatus() async {
    final baseUrl = kIsWeb ? 'http://localhost:8005' : 'http://10.0.2.2:8005';
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/chat/status/${widget.contactId}'));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() => _isContactOnline = data['is_online'] == true);
      }
    } catch (e) {
      debugPrint('Error al consultar estado del contacto: $e');
      if (mounted) {
        setState(() => _isContactOnline = false);
      }
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOutQuad);
      } else {
        _scrollController.jumpTo(target);
      }
    }
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(widget.contactId, text);
    _messageController.clear();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    final currentUserId = currentUser?.id ?? 'MI_ID';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: widget.contactAvatar.isNotEmpty ? NetworkImage(widget.contactAvatar) : null,
              child: widget.contactAvatar.isEmpty
                  ? Text(
                      widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isContactOnline ? 'En línea' : 'Desconectado',
                    style: TextStyle(color: _isContactOnline ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _chatService.messageStream,
              builder: (context, snapshot) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMe = message['sender_id']?.toString() == currentUserId;
                    debugPrint('Message alignment check: isMe=$isMe, sender_id=${message['sender_id']}, currentUserId=$currentUserId');
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _handleSend,
                    backgroundColor: const Color(0xFFEC5B13),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final text = message['message']?.toString() ?? '';
    final timestamp = message['timestamp']?.toString() ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFEC5B13) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(text, style: TextStyle(color: isMe ? Colors.white : const Color(0xFF111827), fontSize: 14)),
              const SizedBox(height: 4),
              Text(timestamp.isNotEmpty ? timestamp.substring(11, 16) : '', style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }
}
