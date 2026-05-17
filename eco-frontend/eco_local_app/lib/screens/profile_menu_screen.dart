import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/user_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/transaction_model.dart';

class ProfileMenuScreen extends ConsumerStatefulWidget {
  const ProfileMenuScreen({super.key});

  @override
  ConsumerState<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends ConsumerState<ProfileMenuScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(walletProvider.notifier).fetchWallet();
    });
  }

  void _showQrDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My QR Code', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: userId,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text('ID: $userId', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showTopUpDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top-up Wallet'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '€'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final success = await ref.read(walletProvider.notifier).topUp(amount);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Top-up successful')));
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSendDialog() {
    final emailController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Recipient Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '€'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0 && emailController.text.isNotEmpty) {
                final success = await ref.read(walletProvider.notifier).sendMoney(emailController.text, amount);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Money sent successfully')));
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showPayDialog() {
    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: merchantController,
              decoration: const InputDecoration(labelText: 'Merchant Name'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '€'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0 && merchantController.text.isNotEmpty) {
                final success = await ref.read(walletProvider.notifier).pay(amount, merchantController.text);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successful')));
                }
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.read(walletProvider.notifier).fetchWallet(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 108),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      color: const Color(0xFFF8F6F6),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text(
                              'Me',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                            ),
                          ),
                          Material(
                            color: const Color(0xFFE2E8F0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.settings_rounded, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // User Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: const DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAPxhmZTx9fqPtjP3GI56Oc4L4bCrcJbKT4_Id1_8wMPTVR15hy0rKYsnR2YLcRRctzWh-vYS_clOOJV9VDgfyizU7pkcbaLHobdANvTUH9p6hAhT9x88ivtuC8hwfXvLIT7EWQx5Ununz7llSpSLC1bxPCPtaubnrNAT4YRI4-c_8QckRdU6dSOJhkNDfounJAwdcBByoYmdjLJCVNtv-I9umWbjdK7wq6-BfbvCoSgzZPjmdkjgeCItzIJkSWhFWUrE4iKzGpIZ7s',
                                  ),
                                ),
                                border: Border.all(color: const Color(0xFFEC5B13).withOpacity(0.3), width: 2),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user?.name ?? 'Alex Johnson',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                        ),
                                      ),
                                      const Icon(Icons.verified, color: Color(0xFFEC5B13), size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${user?.id ?? 'superapp_88291'}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEC5B13).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Premium',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: Color(0xFFEC5B13)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: IconButton(
                                onPressed: () => _showQrDialog(user?.id ?? 'superapp_88291'),
                                icon: const Icon(Icons.qr_code_2, size: 20, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Wallet Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC5B13), Color(0xFFF97316)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFEC5B13).withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 10)),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${walletState.wallet?.balance.toStringAsFixed(2) ?? '0.00'} €',
                                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.account_balance_wallet, size: 32, color: Colors.white70),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _ActionButton(label: 'Pay', icon: Icons.payments, onTap: _showPayDialog),
                                _ActionButton(label: 'Send', icon: Icons.send, onTap: _showSendDialog),
                                _ActionButton(label: 'Top-up', icon: Icons.add_circle, onTap: _showTopUpDialog),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Recent Transactions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECENT TRANSACTIONS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: walletState.isLoading
                                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                                : (walletState.wallet?.transactions.isEmpty ?? true)
                                    ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No transactions yet')))
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: walletState.wallet!.transactions.length > 5 ? 5 : walletState.wallet!.transactions.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                        itemBuilder: (context, index) {
                                          final tx = walletState.wallet!.transactions[index];
                                          return _TransactionTile(tx: tx);
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Identity & Travel
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'IDENTITY & TRAVEL',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                _LinkTile(
                                  icon: Icons.confirmation_number,
                                  iconColor: const Color(0xFF2563EB),
                                  title: 'Digital Tickets',
                                  subtitle: '2 Upcoming trips',
                                ),
                                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                _LinkTile(
                                  icon: Icons.badge,
                                  iconColor: const Color(0xFF7C3AED),
                                  title: 'Digital Passport',
                                  subtitle: 'Verified • Expires 2029',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Mini-Programs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MINI-PROGRAMS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                            children: const [
                              _MiniProgramCard(label: 'Ride Hailing', icon: Icons.local_taxi),
                              _MiniProgramCard(label: 'Food Delivery', icon: Icons.delivery_dining),
                              _MiniProgramCard(label: 'City Services', icon: Icons.location_city),
                              _MiniProgramCard(label: 'Tickets', icon: Icons.movie),
                              _MiniProgramCard(label: 'Shopping', icon: Icons.shopping_bag),
                              _MiniProgramCard(label: 'Health', icon: Icons.fitness_center),
                              _MiniProgramCard(label: 'Charging', icon: Icons.ev_station),
                              _MiniProgramCard(label: 'More', icon: Icons.more_horiz, isDashed: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
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
                      _BottomNavItem(onTap: () => context.go('/chat'), label: 'Chat', icon: Icons.chat_bubble_outline),
                      _BottomNavItem(onTap: () => context.go('/contacts'), label: 'Contacts', icon: Icons.group_outlined),
                      _BottomNavItem(onTap: () => context.go('/discover'), label: 'Discover', icon: Icons.explore_outlined),
                      _BottomNavItem(onTap: () => context.go('/'), label: 'Profile', icon: Icons.account_circle, active: true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isOut = tx.amount < 0;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: (isOut ? Colors.red : Colors.green).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isOut ? Icons.arrow_upward : Icons.arrow_downward, color: isOut ? Colors.red : Colors.green, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text('${tx.date.day}/${tx.date.month}/${tx.date.year}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(
            '${isOut ? '-' : '+'}${tx.amount.abs().toStringAsFixed(2)} €',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOut ? Colors.red : Colors.green),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _LinkTile({required this.icon, required this.iconColor, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _MiniProgramCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDashed;

  const _MiniProgramCard({required this.label, required this.icon, this.isDashed = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: isDashed ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDashed ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0), width: isDashed ? 1.5 : 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: const Color(0xFFEC5B13), size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      ],
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
