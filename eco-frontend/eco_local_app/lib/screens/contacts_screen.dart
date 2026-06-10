import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../services/chat_service.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  late Future<List<Map<String, dynamic>>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    final currentUser = ref.read(userProvider);
    final currentUserId = currentUser?.id ?? '';
    final chatService = ref.read(chatServiceProvider);
    _contactsFuture = chatService.getContacts(currentUserId);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadContacts();
    });
    await _contactsFuture;
  }

  Map<String, List<Map<String, dynamic>>> _groupContactsAlphabetically(List<Map<String, dynamic>> contacts) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final contact in contacts) {
      final name = contact['name'] as String? ?? '';
      final letter = name.isNotEmpty ? name[0].toUpperCase() : '#';
      
      final RegExp alpha = RegExp(r'[A-Z]');
      final key = alpha.hasMatch(letter) ? letter : '#';
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(contact);
    }
    
    final sortedKeys = grouped.keys.toList()..sort();
    final Map<String, List<Map<String, dynamic>>> sortedGrouped = {};
    for (final key in sortedKeys) {
      final list = grouped[key]!;
      list.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
      sortedGrouped[key] = list;
    }
    return sortedGrouped;
  }

  Widget _buildActionTile(IconData icon, Color background, String label, BuildContext context) {
    return InkWell(
      onTap: () {
        if (label == 'New Friends') {
          context.push('/contacts/add').then((_) => _handleRefresh());
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required BuildContext context,
    required String contactId,
    required String title,
    String? avatar,
  }) {
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
        context.push(
          '/chat/detail',
          extra: {
            'contactId': contactId,
            'contactName': title,
            'contactAvatar': avatar ?? '',
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selectedGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(String letter, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Contacts',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Material(
                    color: const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    child: IconButton(
                      onPressed: () => context.push('/contacts/add').then((_) => _handleRefresh()),
                      icon: const Icon(Icons.person_add, color: Color(0xFF111827)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                  hintText: 'Search people or businesses',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: const Color(0xFFEC5B13),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _buildActionTile(Icons.person_add, const Color(0xFFEC5B13), 'New Friends', context),
                            const SizedBox(height: 10),
                            _buildActionTile(Icons.verified, const Color(0xFF3B82F6), 'Official Accounts', context),
                            const SizedBox(height: 10),
                            _buildActionTile(Icons.groups, const Color(0xFF16A34A), 'Groups', context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _contactsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC5B13)),
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20.0),
                                child: Text(
                                  'Error loading contacts: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          }
                          
                          final contacts = snapshot.data ?? [];
                          if (contacts.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No contacts yet',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap "New Friends" or the add button above to search and add contacts.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          final grouped = _groupContactsAlphabetically(contacts);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: grouped.entries.map((entry) {
                              final letter = entry.key;
                              final list = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildGroup(
                                  letter,
                                  list.map((contact) {
                                    return _buildContactRow(
                                      context: context,
                                      contactId: contact['id'] as String,
                                      title: contact['name'] as String? ?? 'No name',
                                      avatar: contact['avatar'] as String?,
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(label: 'Chat', icon: Icons.chat_bubble, onTap: () => context.go('/chat')),
            _NavItem(label: 'Contacts', icon: Icons.contacts, active: true, onTap: () => context.go('/contacts')),
            _NavItem(label: 'Discover', icon: Icons.explore, onTap: () => context.go('/discover')),
            _NavItem(label: 'Profile', icon: Icons.account_circle, onTap: () => context.go('/')),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: active ? const Color(0xFFEC5B13) : const Color(0xFF64748B)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? const Color(0xFFEC5B13) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
