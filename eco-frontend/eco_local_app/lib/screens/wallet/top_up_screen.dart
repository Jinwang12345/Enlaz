import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wallet_provider.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '20');
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  double _selectedAmount = 20.0;
  bool _isLoading = false;

  void _selectAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  void _clearChips() {
    setState(() {
      _selectedAmount = 0;
    });
  }

  Future<void> _handleTopUp() async {
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

    setState(() => _isLoading = true);

    // Simular tiempo de carga del banco como en la maqueta
    await Future.delayed(const Duration(milliseconds: 1800));

    final success = await ref.read(walletProvider.notifier).topUp(amount);

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar la recarga. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
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
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Recarga Exitosa!',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D631B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tu saldo ha sido actualizado. Ya puedes seguir apoyando la economía local.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
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
          'Recargar Saldo',
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
                // Importe título
                const Text(
                  'SELECCIONA EL IMPORTE',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Color(0xFF40493D),
                  ),
                ),
                const SizedBox(height: 16),
                // Amount chips grid
                Row(
                  children: [
                    Expanded(child: _amountChip(10)),
                    const SizedBox(width: 12),
                    Expanded(child: _amountChip(20)),
                    const SizedBox(width: 12),
                    Expanded(child: _amountChip(50)),
                  ],
                ),
                const SizedBox(height: 16),
                // Input amount
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextFormField(
                    controller: _amountController,
                    onChanged: (val) => _clearChips(),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D631B),
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '€',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF40493D),
                          ),
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: 'Otro importe',
                      hintStyle: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor introduce un importe';
                      }
                      final amt = double.tryParse(value);
                      if (amt == null || amt <= 0) {
                        return 'Introduce un número positivo';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Detalles de pago título
                const Text(
                  'DETALLES DE PAGO',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Color(0xFF40493D),
                  ),
                ),
                const SizedBox(height: 16),
                // Payment Form Card
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
                      // Cardholder Name
                      _inputFieldLabel('TITULAR DE LA TARJETA'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cardNameController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration('JUAN PÉREZ'),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // Card Number
                      _inputFieldLabel('NÚMERO DE TARJETA'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CardNumberInputFormatter(),
                        ],
                        decoration: _inputDecoration('0000 0000 0000 0000',
                            suffixIcon: Icons.credit_card),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // Expiry & CVV
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _inputFieldLabel('CADUCIDAD'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    CardExpiryInputFormatter(),
                                  ],
                                  decoration: _inputDecoration('MM / AA'),
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _inputFieldLabel('CVV'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _cvvController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  maxLength: 3,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: _inputDecoration('•••',
                                      suffixIcon: Icons.info_outline,
                                      counterText: ''),
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                    onPressed: _isLoading ? null : _handleTopUp,
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
                                'Procesando...',
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
                                'Confirmar Recarga',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: Colors.white),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Security Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: const Color(0xFF40493D).withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PAGO SEGURO ENCRIPTADO',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: const Color(0xFF40493D).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tus datos están protegidos por el protocolo de seguridad Eco-SSL.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: const Color(0xFF40493D).withOpacity(0.6),
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

  Widget _amountChip(double amount) {
    final isActive = _selectedAmount == amount;
    return GestureDetector(
      onTap: () => _selectAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D631B).withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${amount.toStringAsFixed(0)}€',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isActive ? Colors.white : const Color(0xFF0D631B),
          ),
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

  InputDecoration _inputDecoration(String hint, {IconData? suffixIcon, String? counterText}) {
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
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: const Color(0xFF40493D).withOpacity(0.4), size: 20)
          : null,
      counterText: counterText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 2) {
      text = '${text.substring(0, 2)} / ${text.substring(2, math.min(4, text.length))}';
    }
    return newValue.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length));
  }
}
