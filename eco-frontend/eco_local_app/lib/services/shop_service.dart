import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/shop.dart';

class ShopService {
  final String baseUrl = kIsWeb
      ? 'http://localhost:8005'
      : 'http://10.0.2.2:8005';

  /// Obtiene los comercios cercanos a una ubicación dada.
  /// [lat] Latitud del usuario.
  /// [lng] Longitud del usuario.
  /// [radius] Radio de búsqueda en metros.
  Future<List<Shop>> getNearbyShops(double lat, double lng, {double radius = 100, int limit = 40}) async {
    try {
      final url = Uri.parse('$baseUrl/wallet/shops/nearby?lat=$lat&lng=$lng&radius=$radius&limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Shop.fromJson(item)).toList();
      } else {
        debugPrint('Error fetching nearby shops: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception in getNearbyShops: $e');
      return [];
    }
  }
}
