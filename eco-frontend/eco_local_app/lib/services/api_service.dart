import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/user_model.dart';

class ApiService {
  // Backend URL - apuntando al backend LAIA en puerto 8005
  final String baseUrl = kIsWeb
      ? 'http://localhost:8005'
      : 'http://10.0.2.2:8005';

  ApiService();

  // 1. Autenticación - Login
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/user/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        print('Login failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  // 2. Autenticación - Registro
  Future<UserModel?> register(String name, String email, String password, {String? surnames}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/user/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          if (surnames != null && surnames.isNotEmpty) 'surnames': surnames,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // El backend devuelve {"user": {...}, "token": "..."}
        if (data is Map && data.containsKey('user')) {
          return UserModel.fromJson(data['user']);
        }
        return UserModel.fromJson(data);
      } else {
        print('Registration failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during registration: $e');
      return null;
    }
  }

  // 3. Obtener productos
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // 4. Comprar producto
  Future<bool> buyProduct(String productId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shop/buy'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'productId': productId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Purchase successful');
        return true;
      } else {
        print('Purchase failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error buying product: $e');
      return false;
    }
  }
}
