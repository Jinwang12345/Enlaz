import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

// Gestiona el carrito/compra actual
class CartNotifier extends StateNotifier<List<ProductModel>> {
  CartNotifier() : super([]);

  void addProduct(ProductModel product) {
    state = [...state, product];
  }

  void removeProduct(ProductModel product) {
    state = state.where((p) => p.id != product.id).toList();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<ProductModel>>((
  ref,
) {
  return CartNotifier();
});
