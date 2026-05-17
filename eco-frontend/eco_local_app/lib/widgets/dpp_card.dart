import 'package:flutter/material.dart';

// Tarjetita que muestra el impacto CO2
class DppCard extends StatelessWidget {
  final double co2Impact;

  const DppCard({super.key, required this.co2Impact});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Impacto CO2: $co2Impact kg'),
      ),
    );
  }
}
