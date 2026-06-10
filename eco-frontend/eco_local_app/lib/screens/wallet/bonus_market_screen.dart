import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bonus_template_model.dart';
import '../../models/user_bonus_model.dart';
import '../../models/campaign_model.dart';

import '../../services/bonus_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/wallet_provider.dart';

class BonusMarketScreen extends ConsumerStatefulWidget {
  const BonusMarketScreen({super.key});

  @override
  ConsumerState<BonusMarketScreen> createState() => _BonusMarketScreenState();
}

class _BonusMarketScreenState extends ConsumerState<BonusMarketScreen> {
  final Color _brandOrange = const Color(0xFFEC5B13);
  final Color _greenLight = const Color(0xFFDCFCE7);
  final Color _surface = const Color(0xFFFFFFFF);
  final Color _border = const Color(0xFFE5E7EB);

  final BonusService _bonusService = BonusService();

  late Future<List<BonusTemplateModel>> _templatesFuture;
  Future<List<UserBonusModel>>? _myBonusesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = _bonusService.getAvailableTemplates();
    _loadMyBonuses();
  }

  void _loadMyBonuses() {
    final user = ref.read(userProvider);
    if (user != null && user.id != null && user.token != null) {
      _myBonusesFuture = _bonusService.getMyBonuses(
        userId: user.id!,
        token: user.token!,
      );
    }
  }

  void _refreshAll() {
    setState(() {
      _templatesFuture = _bonusService.getAvailableTemplates();
      _loadMyBonuses();
    });
  }

  Future<void> _handleBuy(BonusTemplateModel template) async {
    final user = ref.read(userProvider);
    if (user == null || user.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comprar bonos')),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar compra'),
        content: Text(
          '¿Quieres adquirir "${template.title}"?\n\n'
          'Se descontarán ${template.costPrice.toStringAsFixed(0)}€ de tu saldo '
          'y recibirás ${template.spendingValue.toStringAsFixed(0)}€ en un bono canjeable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Adquirir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _bonusService.buyBonus(
      templateId: template.id,
      token: user.token!,
    );

    // Dismiss loading
    if (mounted) Navigator.pop(context);

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión')),
        );
      }
      return;
    }

    if (result.containsKey('error')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'].toString())),
        );
      }
      return;
    }

    // Success – refresh wallet and bonuses list
    ref.read(walletProvider.notifier).fetchWallet();
    _refreshAll();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡${template.title} adquirido correctamente!'),
          backgroundColor: const Color(0xFF166534),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F5),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF5F7F5),
          foregroundColor: const Color(0xFF14532D),
          titleSpacing: 0,
          title: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Bonos de Consumo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF14532D),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF14532D)),
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Aprovecha bonos locales y suma saldo extra en tu wallet.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _greenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_offer_rounded, color: Color(0xFF166534)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonus Market',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14532D),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Compra bonos disponibles o revisa los que ya tienes.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: const Color(0xFF111827),
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: _brandOrange,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    tabs: const [
                      Tab(text: 'Disponibles'),
                      Tab(text: 'Mis Bonos'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAvailableTab(),
                      _buildMyBonusesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Available Templates Tab ─────────────────────────────────────────────────
  Widget _buildAvailableTab() {
    final myFuture = _myBonusesFuture ?? Future.value(<UserBonusModel>[]);
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_templatesFuture, myFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        
        final List<dynamic> results = snapshot.data ?? [[], []];
        final List<BonusTemplateModel> templates = List<BonusTemplateModel>.from(results[0]);
        final List<UserBonusModel> myBonuses = List<UserBonusModel>.from(results[1]);

        if (templates.isEmpty) {
          return const Center(
            child: Text('No hay bonos disponibles en este momento.',
                style: TextStyle(color: Color(0xFF6B7280))),
          );
        }

        // Group templates by campaign
        final campaignMap = <String, CampaignModel>{};
        final templatesByCampaign = <String, List<BonusTemplateModel>>{};
        final noCampaignTemplates = <BonusTemplateModel>[];

        for (final t in templates) {
          if (t.campaign != null) {
            campaignMap[t.campaign!.id] = t.campaign!;
            templatesByCampaign.putIfAbsent(t.campaign!.id, () => []).add(t);
          } else {
            noCampaignTemplates.add(t);
          }
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            ...campaignMap.values.map((campaign) {
              final campaignTemplates = templatesByCampaign[campaign.id] ?? [];
              final userQuotaUsed = myBonuses.where((ub) => ub.campaignId == campaign.id || ub.template?.campaignId == campaign.id).length;
              final isQuotaExceeded = userQuotaUsed >= campaign.maxBonusesPerUser;
              final isBudgetExhausted = campaign.remainingBudget <= 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campaign Card Header
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14532D), Color(0xFF166534)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.campaign_rounded, color: Colors.amber, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                campaign.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                campaign.status.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                        if (campaign.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            campaign.description!,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Budget Progress bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Presupuesto: ${campaign.remainingBudget.toStringAsFixed(0)}€ restantes de ${campaign.totalBudget.toStringAsFixed(0)}€',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            Text(
                              '${((campaign.remainingBudget / campaign.totalBudget) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (campaign.remainingBudget / campaign.totalBudget).clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isBudgetExhausted ? Colors.red : (campaign.remainingBudget / campaign.totalBudget < 0.2 ? Colors.orange : Colors.greenAccent)
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // User Limit status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isQuotaExceeded ? Icons.lock_outline : Icons.assignment_ind_outlined,
                                size: 16,
                                color: isQuotaExceeded ? Colors.redAccent : Colors.greenAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tu consumo en esta campaña: $userQuotaUsed / ${campaign.maxBonusesPerUser} bonos',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isQuotaExceeded ? Colors.red.shade200 : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // List of Campaign templates
                  ...campaignTemplates.map((bonus) {
                    final savings = bonus.spendingValue - bonus.costPrice;
                    final isBuyDisabled = isQuotaExceeded || isBudgetExhausted || savings > campaign.remainingBudget;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _greenLight,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  bonus.savingsLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.attach_money_rounded, color: Color(0xFFEC5B13), size: 18),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            bonus.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bonus.description,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isBudgetExhausted 
                                ? 'Presupuesto agotado para esta campaña.'
                                : isQuotaExceeded
                                    ? 'Has alcanzado el límite máximo permitido para esta campaña.'
                                    : 'Saldo extra subvencionado por el ayuntamiento.',
                            style: TextStyle(
                              fontSize: 12, 
                              color: isQuotaExceeded || isBudgetExhausted ? Colors.red.shade700 : Colors.green.shade700,
                              fontWeight: isQuotaExceeded || isBudgetExhausted ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isBuyDisabled ? null : () => _handleBuy(bonus),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBuyDisabled ? Colors.grey.shade300 : _brandOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: Text(
                                isBudgetExhausted 
                                    ? 'Presupuesto Agotado' 
                                    : isQuotaExceeded 
                                        ? 'Límite Superado' 
                                        : 'Adquirir', 
                                style: const TextStyle(fontWeight: FontWeight.w800)
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),
            // Templates without campaign (legacy fallback)
            if (noCampaignTemplates.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Otros Bonos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                ),
              ),
              ...noCampaignTemplates.map((bonus) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bonus.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(bonus.description),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleBuy(bonus),
                          style: ElevatedButton.styleFrom(backgroundColor: _brandOrange),
                          child: const Text('Adquirir'),
                        ),
                      )
                    ],
                  ),
                );
              }),
            ]
          ],
        );
      },
    );
  }

  // ─── My Bonuses Tab ──────────────────────────────────────────────────────────
  Widget _buildMyBonusesTab() {
    if (_myBonusesFuture == null) {
      return const Center(
        child: Text('Inicia sesión para ver tus bonos.',
            style: TextStyle(color: Color(0xFF6B7280))),
      );
    }

    return FutureBuilder<List<UserBonusModel>>(
      future: _myBonusesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        final bonuses = snapshot.data ?? [];
        if (bonuses.isEmpty) {
          return const Center(
            child: Text('Aún no tienes bonos. ¡Compra uno en la pestaña "Disponibles"!',
                style: TextStyle(color: Color(0xFF6B7280))),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          itemCount: bonuses.length,
          separatorBuilder: (_, b) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final bonus = bonuses[index];
            final title = bonus.template?.title ?? 'Bono';
            final validUntil = bonus.template?.formattedExpiration ?? '';
            final amount = '${bonus.template?.spendingValue.toStringAsFixed(0) ?? "?"}€ de saldo';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.confirmation_num_rounded, color: Color(0xFFEC5B13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          validUntil,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          amount,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showQrBottomSheet(context, bonus),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              foregroundColor: const Color(0xFF92400E),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                            label: const Text('Ver código QR', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => _showQrBottomSheet(context, bonus),
                    icon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFFEC5B13), size: 30),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFF7ED)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── QR Bottom Sheet ─────────────────────────────────────────────────────────
  void _showQrBottomSheet(BuildContext context, UserBonusModel bonus) {
    final title = bonus.template?.title ?? 'Bono';
    final validUntil = bonus.template?.formattedExpiration ?? '';
    final amountValue = bonus.template?.spendingValue.toStringAsFixed(0) ?? '?';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(Icons.qr_code_2_rounded, size: 220, color: Color(0xFFEC5B13)),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  validUntil,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                // QR token for merchant scanning
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    bonus.qrToken,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Muestra este código QR en la caja del comercio para aplicar tus $amountValue€ de saldo.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
