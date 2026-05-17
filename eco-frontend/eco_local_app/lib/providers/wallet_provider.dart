import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../data/services/wallet_service.dart';
import 'user_provider.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

class WalletState {
  final WalletModel? wallet;
  final bool isLoading;
  final String? error;

  WalletState({this.wallet, this.isLoading = false, this.error});

  WalletState copyWith({WalletModel? wallet, bool? isLoading, String? error}) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletService _walletService;
  final Ref _ref;

  WalletNotifier(this._walletService, this._ref) : super(WalletState());

  String? get _token => _ref.read(userProvider)?.token;

  Future<void> fetchWallet() async {
    if (_token == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final wallet = await _walletService.fetchWallet(_token!);
      if (wallet != null) {
        state = state.copyWith(wallet: wallet, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to fetch wallet');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> topUp(double amount) async {
    if (_token == null) return false;
    
    try {
      final newBalance = await _walletService.topUp(_token!, amount);
      if (newBalance != null) {
        await fetchWallet(); // Refresh wallet data
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }

  Future<bool> sendMoney(String recipientEmail, double amount) async {
    if (_token == null) return false;
    
    try {
      final newBalance = await _walletService.sendMoney(_token!, recipientEmail, amount);
      if (newBalance != null) {
        await fetchWallet();
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }

  Future<bool> pay(double amount, String merchant) async {
    if (_token == null) return false;
    
    try {
      final newBalance = await _walletService.pay(_token!, amount, merchant);
      if (newBalance != null) {
        await fetchWallet();
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final walletService = ref.watch(walletServiceProvider);
  return WalletNotifier(walletService, ref);
});
