import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/bonus_template_model.dart';
import '../models/user_bonus_model.dart';

class BonusService {
  // Matches the same baseUrl logic as the rest of the app services.
  final String baseUrl = kIsWeb
      ? 'http://localhost:8005'
      : 'http://10.0.2.2:8005';

  // ── GET /api/bonuses/templates ─────────────────────────────────────────────
  Future<List<BonusTemplateModel>> getAvailableTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bonuses/templates'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(response.body) as List<dynamic>;
        return data
            .map((e) =>
                BonusTemplateModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint(
            'getAvailableTemplates failed: ${response.statusCode} – ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getAvailableTemplates: $e');
      return [];
    }
  }

  // ── POST /api/bonuses/buy/{template_id} ───────────────────────────────────
  /// Returns the new wallet balance on success, or null on failure.
  Future<Map<String, dynamic>?> buyBonus({
    required String templateId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/bonuses/buy/$templateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Surface the backend error message to the UI layer.
        final body = json.decode(response.body);
        final detail = (body is Map ? body['detail'] : null) ??
            'Error al adquirir el bono';
        return {'error': detail};
      }
    } catch (e) {
      debugPrint('Error in buyBonus: $e');
      return {'error': e.toString()};
    }
  }

  // ── GET /api/bonuses/my-bonuses/{user_id} ─────────────────────────────────
  Future<List<UserBonusModel>> getMyBonuses({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bonuses/my-bonuses/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(response.body) as List<dynamic>;
        return data
            .map((e) =>
                UserBonusModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint(
            'getMyBonuses failed: ${response.statusCode} – ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getMyBonuses: $e');
      return [];
    }
  }
}
