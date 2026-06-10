import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/chat_service.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _emailController = TextEditingController();
  final _conceptController = TextEditingController(text: 'Bizum');
  
  late Future<List<Map<String, dynamic>>> _contactsFuture;
  Map<String, dynamic>? _selectedContact;
  bool _isLoading = false;
  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(userProvider);
    final chatService = ref.read(chatServiceProvider);
    _contactsFuture = chatService.getContacts(currentUser?.id ?? '').then((contacts) {
      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
      });
      return contacts;
    });
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        final name = (contact['name'] ?? '').toString().toLowerCase();
        final email = (contact['email'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) || email.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _selectContact(Map<String, dynamic> contact) {
    setState(() {
      _selectedContact = contact;
      _emailController.text = contact['email'] ?? '';
    });
  }

  void _deselectContact() {
    setState(() {
      _selectedContact = null;
      _emailController.clear();
    });
  }

  Future<void> _handleSendMoney() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, introduce un importe válido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, especifica un destinatario.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simular retraso de Bizum
    await Future.delayed(const Duration(milliseconds: 1500));

    final success = await ref.read(walletProvider.notifier).sendMoney(email, amount);

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showSuccessDialog(email, amount);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar el dinero. Comprueba el correo del destinatario y tu saldo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(String email, double amount) {
    final displayName = _selectedContact != null ? _selectedContact!['name'] : email;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D631B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Envío Exitoso!',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D631B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Se han enviado ${amount.toStringAsFixed(2)}€ a $displayName correctamente.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF40493D),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Cerrar diálogo
                          context.pop(); // Volver al perfil
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E2E2),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Volver al Perfil',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF0D631B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _emailController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9).withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D631B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Enviar Dinero (Bizum)',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: Color(0xFF0D631B),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                if (_selectedContact == null) ...[
                  // Buscar contacto
                  const Text(
                    'SELECCIONA UN CONTACTO',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0xFF40493D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo Buscar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      onChanged: _filterContacts,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        hintText: 'Buscar por nombre o email',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Lista de contactos
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _contactsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0D631B))),
                        );
                      }
                      
                      if (snapshot.hasError || _allContacts.isEmpty) {
                        return _buildManualInputSection();
                      }

                      return Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filteredContacts.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            final name = contact['name'] ?? 'Contacto';
                            final email = contact['email'] ?? '';
                            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0D631B).withOpacity(0.12),
                                child: Text(
                                  initial,
                                  style: const TextStyle(color: Color(0xFF0D631B), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              onTap: () => _selectContact(contact),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Campo manual si no se selecciona contacto de lista
                  const Text(
                    'O INTRODUCE EL EMAIL DIRECTAMENTE',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0xFF40493D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('destinatario@enlaz.com', prefixIcon: Icons.alternate_email),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                    validator: (value) {
                      if (_selectedContact == null && (value == null || value.isEmpty)) {
                        return 'Introduce el correo del destinatario';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  // Contacto Seleccionado Card
                  const Text(
                    'DESTINATARIO SELECCIONADO',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0xFF40493D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D631B).withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ],
                      border: Border.all(color: const Color(0xFF0D631B).withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF0D631B).withOpacity(0.12),
                          radius: 24,
                          child: Text(
                            _selectedContact!['name'] != null && _selectedContact!['name'].isNotEmpty
                                ? _selectedContact!['name'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Color(0xFF0D631B), fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedContact!['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF002204)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedContact!['email'] ?? '',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: _deselectContact,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                
                // Formulario de envío
                const Text(
                  'DATOS DE LA TRANSFERENCIA',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Color(0xFF40493D),
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D631B).withOpacity(0.04),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Importe
                      _inputFieldLabel('IMPORTE (€)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: _inputDecoration('0.00', prefixIcon: Icons.euro_symbol),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Introduce el importe a enviar';
                          }
                          final amt = double.tryParse(value);
                          if (amt == null || amt <= 0) {
                            return 'Introduce un número positivo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Concepto
                      _inputFieldLabel('CONCEPTO (OPCIONAL)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _conceptController,
                        decoration: _inputDecoration('Bizum / Regalo / Comida'),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // Confirm Button
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D631B), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D631B).withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendMoney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Procesando Envío...',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Enviar Bizum',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No tienes contactos agregados. Escribe el correo del destinatario abajo para enviarle dinero.',
                style: TextStyle(fontSize: 13, color: Colors.orange, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: const Color(0xFF40493D).withOpacity(0.8),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? prefixIcon, String? counterText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        color: const Color(0xFF40493D).withOpacity(0.3),
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D631B), width: 1),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: const Color(0xFF40493D).withOpacity(0.4), size: 20)
          : null,
      counterText: counterText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
