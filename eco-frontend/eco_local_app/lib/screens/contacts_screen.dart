import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  Widget _buildActionTile(IconData icon, Color background, String label, BuildContext context) {
    return InkWell(
      onTap: () {},
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

  Widget _buildContactRow({Widget? avatar, required String title}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            avatar ??
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    title.isNotEmpty ? title[0] : '?',
                    style: const TextStyle(
                      color: Color(0xFF334155),
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
                      onPressed: () {},
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
              child: SingleChildScrollView(
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
                    _buildGroup('A', [
                      _buildContactRow(
                        avatar: CircleAvatar(
                          radius: 20,
                          backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuD6qy8zpwWbFIF9nJJ-GHwArU7D96BFJMNTnh0bJp3Okxdwg1T39kohCz6_O-18Wx1LX_BdD_qzp_L66i6Ozz8sGjX_Kye23Kegms5QvpeWWt41L69ddHiozHe3QHo5iKUIjFpHzOFcpV1zWOnK8NCPHL-bVmTEdPLsE_YkeaMGSCD3tpSS1ZShB8_mtsACbv2fqtLDhceaZBsHQGib5NO8A32V8x8SfXvPp9ssbEU-6hfi_8laaXvLVwXWL-MSQNejwM19QNiy4Y9i'),
                        ),
                        title: 'Adeline Miller',
                      ),
                      _buildContactRow(
                        avatar: CircleAvatar(
                          radius: 20,
                          backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDpFKkJXcCYwjKY57M1XTMX7VYKnm6GG56hlyypuxBwaWQvOxW8blGL4y1gAwt3kj76v2EKIi2l8w7Y3UieY3jleXKl-5fjWC5GRYFtzT08mrVPeSfmljkR_AIWM3V_NGwVvWFjsEYfN6TmehjjUs38kJIY812-Z3gHAFF0KLvoWobAmO4DS8-ErYX4i3S_77hLui7nmHCSmLhAntUaSKgAhU_YRTxgrO2Ml_LezefdA8wRgjwtttY84ebR9HD8Iz2eFOgsJddF-n32'),
                        ),
                        title: 'Arthur Morgan',
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildGroup('B', [
                      _buildContactRow(
                        avatar: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC5B13),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: 'Bistro 24 (Business)',
                      ),
                      _buildContactRow(
                        avatar: CircleAvatar(
                          radius: 20,
                          backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuC6XH7PyuBVc1skPRJyWB7yRlKk0pPXaUcSLZqI5CR3evtcL3VMiAPxueosTJ4OzKfn63b4cdVzFpDJiQWEiWUxPkzosGd5toc8BGk5fiX__gGzoVCDU6WUSEfrGsvPIjDv8e4VJuObLHdDhgws__RhfG68AGc38AjfMLP5gPu53pnpqWZxBVupR6NNJULajfQaKUQVKtwnPNeI5jTpZ0tuOIUqDcTxajnRkhztKsAarWlzUOYfWz46H5oPbaW33tzv-whXDI78G_Ts'),
                        ),
                        title: 'Benjamin Hayes',
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildGroup('C', [
                      _buildContactRow(
                        avatar: CircleAvatar(
                          radius: 20,
                          backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuA1fHwpL5F1qG9R1ZyFRW179Nx1sl8sIOIhIJ8tNkzmaVX-sWeDR_DH48PPmAASDNriDNUe9ntHhadazJJjYn2GMcRMXEpRs-eUU7PdLMS9o7gmZqzmSKOC5hOsMQeebETwuJVIb3u1QOMk7knIktgVdrkf7K2UQwCaGkZgJ9f63lO62XoMQ45MTwVkRQRtMfSF0V6cF2kOrS_e-KKxCERVSSucmmsfzwjxvJyQw-SqqGAU65j62v9ZxkhvEBf9WbCxQot_dOw97cU-'),
                        ),
                        title: 'Catherine Pierce',
                      ),
                      _buildContactRow(
                        title: 'Cloud Services Corp',
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildGroup('D', [
                      _buildContactRow(
                        avatar: CircleAvatar(
                          radius: 20,
                          backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBPNQw9k22N-E8MAneUzZFCfesoMJF6_EvMT35KUk7bN7k4dpKufhinGPeW37c5xaahs78NphRlVKc8NRlDQU3sYskNr7DloyJgOpIKtvJr6yOf42OGi0OEQVAk71EvevyWjJrSXFkkFP1Brvx3rg24MPnSsIDGBzHw78jB2psq9IbG-Q4PyZHy7sAUVXZzHtiOU0tG2gydIIUHL8WdABdehZrrAsRT_GSdY59q_FQQcy9LY70oetLceWYitTx_MGHJwsgJ_kCdM8g6'),
                        ),
                        title: 'David Chen',
                      ),
                    ]),
                    const SizedBox(height: 80),
                  ],
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
