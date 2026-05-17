import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

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
            onPressed: () {},
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
      body: ListView(
        children: [
          _ChatTile(
            name: 'Sarah Jenkins',
            message: 'Are we still meeting at 5? I\'ve got the tickets ready!',
            time: '09:12 AM',
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB9MkeststV_AVVZCyvK0PKvBLLpgi6veHazqge0rDh8f98c8RkUzD3YRZ0lZzklSvGjXfYGuBRPxlnOQg_-2fKtb_DMpR6gMaGEFb_k4ZeZ1nI2CWMy5LlVvKiwBfy8tao191xaUhCOdJDRiGMVpgOImWC1PqTZDQ-bH8khq2JaxVsvZAqTb0FRt0v7O-UyLeJFCESi8J2Fnbj_TcInRzwLexSf4rWTOe7jHaaNzBnWO-o9O6aDywNhpVHGhkM5K2LSfI8wYVuGkRh',
            unreadCount: 2,
          ),
          _ChatTile(
            name: 'Zapatería Fernando',
            message: 'Thanks for your purchase! ✅',
            time: '10:45 AM',
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD8a5xgz7LfW-qfTKbAntmr-s1sWDf0Nh1d7YzyjkOBOifISjVgIOTx0M4Jpt81NeLjnn074Vxgp7jK_vGCRMiPgbi1qHV9nlz_f00-ynvDS9ckCn55pGQmH89LAQFG1tsJU1ZT4CWbSHf4gNDIEjDXajziXglvPzFOy__rTlwkOFC_mmbUNbMIHIaHDaIQC-j1UxlRi3BBqwE6aWOHYCeOY_1nY1xUOMjW593-i-Aa4f2v5NqN8RuPXmh1kaVYHFLzDlws6Z_ykz2L',
            isVerified: true,
            isPrimaryMessage: true,
          ),
          _ChatTile(
            name: 'David Chen',
            message: 'Here is your Digital Passport for the event.',
            time: 'Yesterday',
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDnGbwVpa2uzDIUdGpm0K4clw_g33GyHynhGHfPJQ782vAxyXbOypAx-0hR7wIOdHXfqQ-0kHT9GbG9CLYv0hWF1AUhMjTvt-zN-z9ZrlGz7w-fAczsZPgSploS5GJeeKrXRMHH3sNWm7UY8KLcmEDZfypbrZdh4B7HoVeOJ5_yjnpqAqmce-l-TN79MaR4TM4gJcdH8afqcQ_fqWZDTwwFbO-iZPN_ehnGMTAo-rZ4RWdkXsY4tGH9yqTbCagscXD3TMW2wgG1yOjR',
          ),
          _ChatTile(
            name: 'Wallet Services',
            message: 'You received a payment of 45.00 € from Alex.',
            time: 'Monday',
            icon: Icons.account_balance_wallet,
            isVerified: true,
          ),
          _GroupChatTile(
            name: 'Weekend Hiking Crew',
            message: 'Alex: Should we bring extra water?',
            time: 'Oct 24',
            images: [
              'https://lh3.googleusercontent.com/aida-public/AB6AXuA6nlYT39CZ6cg7mIJgWSueNzlYbCey9nz_E7UbvuIG2D_FQ7Thfg0M9jf6N2ufLjuQ_v3HCikVwk_UVlQAnJ1TiahR66hFy0rqgM-fOychWAWymVJ-K0cjcazrCUeoUWZGMaMkkjVi-6uz9UXNr2vWHsB6rOia1lX3y63jkm0DGzVHT9sJ7Em1o54ltRZK28evSIgnHYzdqLcpoA1ZCENngEBCj-v7Vsv0g9ZiDxXxqwfZFqWqC5aAAfAULaufSxToVU_y6xoz192s',
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBwnfSTztAloixmGKtzT2-gC__dPWOczflcRm0RHjS494izgfxm2SoHEP7denGajTn2Q9Piegf_x4Fd7RJ8P1quSLy4jbhNgNOVp6UdIUG0sSWbfQeld3Ma26OJPiJroCCDxJJCQRpQ-LRvM9LVopawFFYQguXoHUDpWPneTiNlhIocGxibKD51HrbtWamvOb3MCPJXK3ekXIvV9TU8xNcGDxyf2OrJFHgqM0FazXpU_z9IYZPqwDcGovg8fEH9YnoDn0r0UAs7lS9f',
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCMFA9SDjhQPDsOyw8UnAghO3k8YxySczCaFMOYFMIDxFCWVbH_K6aZtnwvlzYk2hTqoOIISh3Z1cjKBOEDPrPQ6XBJ8A9-73r2lCkVOmKRRGtHQfeEEmaDeUDHFezMmDlYS4W6qqpjBpOh6VuRbTT425Jb6xI2ZuQWWg6JvHyKELVxqNXJMHJLl8_Ks3Wt-f-O_dO6yP_VIh2Y1x-Uerlfnce2Q-HaUzEXhcYOWeJGPQq8dtxKoeFdqhBjscxGlpCDAv0Ann00MNkp',
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCsYpcJWQSKL1oOKijSfkZg8lIm_Vgtg1d-IdMt67NKbYqCavOUFVu9snk9Q7yg3VTXImzJLHTceM_0orEAknqjTtCTkhJG3YH-kV8kmGgRj6Y1L77rWCRo_IKMx4vORI75te1dqhWeVhJZcb5GGmWe5EH9csVa2uq5AHaW6AGQPlGWohKEgBfLeE-yS_Oh2ZlPJATB4ocFZQ_oNkCO7oqw_cN7ELZq1TD1HUTK0ie1QBHNJQdvyC5CdyQukVUzqKtAbrKTyD-H9RfQ',
            ],
          ),
        ],
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
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String? imageUrl;
  final IconData? icon;
  final int unreadCount;
  final bool isVerified;
  final bool isPrimaryMessage;

  const _ChatTile({
    required this.name,
    required this.message,
    required this.time,
    this.imageUrl,
    this.icon,
    this.unreadCount = 0,
    this.isVerified = false,
    this.isPrimaryMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
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
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    image: imageUrl != null
                        ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: icon != null
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

class _GroupChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final List<String> images;

  const _GroupChatTile({
    required this.name,
    required this.message,
    required this.time,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(1),
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
                children: images.take(4).map((url) => Image.network(url, fit: BoxFit.cover)).toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
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
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
