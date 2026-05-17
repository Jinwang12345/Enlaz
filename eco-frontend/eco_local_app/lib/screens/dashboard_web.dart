import 'package:flutter/material.dart';

// Pantalla exclusiva para la versión Web
class DashboardWebScreen extends StatelessWidget {
  const DashboardWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Web')),
      body: const Center(child: Text('Pantalla exclusiva para la versión Web')),
    );
  }
}
