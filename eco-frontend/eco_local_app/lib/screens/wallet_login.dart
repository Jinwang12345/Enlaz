import 'package:flutter/material.dart';

// Pantalla de login simulado
class WalletLoginScreen extends StatelessWidget {
  const WalletLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Pantalla de login simulado')),
    );
  }
}
