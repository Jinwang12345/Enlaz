import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

// Provider para el ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Gestiona el estado del usuario y autenticación
class UserNotifier extends StateNotifier<UserModel?> {
  final ApiService _apiService;

  UserNotifier(this._apiService) : super(null);

  // Login
  Future<bool> login(String email, String password) async {
    final user = await _apiService.login(email, password);
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  // Register
  Future<bool> register(String name, String email, String password, {String? surnames}) async {
    final user = await _apiService.register(name, email, password, surnames: surnames);
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  // Logout
  void logout() {
    state = null;
  }

  // Check if user is logged in
  bool get isLoggedIn => state != null;
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserNotifier(apiService);
});
