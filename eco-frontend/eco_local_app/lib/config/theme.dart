import 'package:flutter/material.dart';

// Colores y fuentes de la app
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.green, // Example color
      // Define fonts here using debug-friendly/unavailable GoogleFonts if needed
    );
  }
}
