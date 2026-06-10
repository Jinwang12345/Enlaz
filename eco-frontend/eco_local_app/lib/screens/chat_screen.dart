import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../services/chat_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late Future<List<Map<String, dynamic>>> _conversationsFuture;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    
    // Escuchar mensajes entrantes en tiempo real (WebSocket) para recargar la lista de chats
    final chatService = ref.read(chatServiceProvider);
    _messageSubscription = chatService.messageStream.listen((_) {
      if (mounted) {
        setState(() {
          _loadConversations();
        });
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _loadConversations() {
    final currentUser = ref.read(userProvider);
    final currentUserId = currentUser?.id ?? '';
    final chatService = ref.read(chatServiceProvider);
    _conversationsFuture = chatService.getConversations(currentUserId);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadConversations();
    });
    await _conversationsFuture;
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dateTime.weekday - 1];
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(color: Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Color(0xFF374151)),
          ),
          IconButton(
            onPressed: () => context.push('/contacts/add').then((_) => _handleRefresh()),
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  hintText: 'Search conversations',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFEC5B13),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _conversationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC5B13)),
                ),
              );
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Error loading chats: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            final conversations = snapshot.data ?? [];
            if (conversations.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final chat = conversations[index];
                return ChatTile(
                  contactId: chat['contactId'] as String,
                  name: chat['name'] as String? ?? 'No name',
                  message: chat['last_message'] as String? ?? '',
                  time: _formatTimestamp(chat['timestamp'] as String?),
                  onPop: _handleRefresh,
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -6))],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(onTap: () => context.go('/chat'), label: 'Chat', icon: Icons.chat_bubble, active: true),
              _BottomNavItem(onTap: () => context.go('/contacts'), label: 'Contacts', icon: Icons.group_outlined),
              _BottomNavItem(onTap: () => context.go('/discover'), label: 'Discover', icon: Icons.explore_outlined),
              _BottomNavItem(onTap: () => context.go('/'), label: 'Profile', icon: Icons.account_circle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 50,
                  color: Color(0xFFEC5B13),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No active chats',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Start a conversation by adding a friend and tapping on their name in contacts!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatTile extends StatelessWidget {
  final String contactId;
  final String name;
  final String message;
  final String time;
  final String? imageUrl;
  final IconData? icon;
  final int unreadCount;
  final bool isVerified;
  final bool isPrimaryMessage;
  final VoidCallback? onPop;

  const ChatTile({
    super.key,
    required this.contactId,
    required this.name,
    required this.message,
    required this.time,
    this.imageUrl,
    this.icon,
    this.unreadCount = 0,
    this.isVerified = false,
    this.isPrimaryMessage = false,
    this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    // Generate styled initials avatar with random gradient based on contact ID
    final colorIndex = contactId.hashCode % 5;
    final gradients = [
      [const Color(0xFFEC5B13), const Color(0xFFFF8C39)],
      [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
      [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
    ];
    final selectedGradient = gradients[colorIndex];

    return InkWell(
      onTap: () {
        context.push('/chat/detail', extra: {
          'contactId': contactId,
          'contactName': name,
          'contactAvatar': imageUrl ?? '',
        }).then((_) {
          if (onPop != null) {
            onPop!();
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: imageUrl == null
                        ? LinearGradient(
                            colors: selectedGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    image: imageUrl != null
                        ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imageUrl == null && icon == null
                      ? Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : icon != null
                          ? Icon(icon, color: const Color(0xFFEC5B13), size: 28)
                          : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC5B13),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          ),
                          if (isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified, size: 16, color: Colors.green),
                            ),
                        ],
                      ),
                      Text(
                        time,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isPrimaryMessage ? const Color(0xFFEC5B13) : const Color(0xFF64748B),
                      fontWeight: isPrimaryMessage ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({required this.label, required this.icon, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? const Color(0xFFEC5B13) : const Color(0xFF64748B)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: active ? const Color(0xFFEC5B13) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
