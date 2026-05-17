import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8005';

  Future<UserModel?> registerUser(UserModel user) async {
    final url = Uri.parse('$baseUrl/auth/register/user/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('user')) {
        return UserModel.fromJson(data['user']);
      }
      return UserModel.fromJson(data);
    } else {
      print('Registration failed: ${response.statusCode} - ${response.body}');
      return null;
    }
  }
}