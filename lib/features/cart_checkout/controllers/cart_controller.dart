import 'package:flutter/foundation.dart';
import '../../product/models/product_model.dart';
import '../models/cart_item_model.dart';

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount {
    return _items.fold(
      0,
      (total, item) => total + item.quantity,
    );
  }

  double get totalPrice {
    return _items.fold(
      0,
      (total, item) => total + item.totalPrice,
    );
  }

  // เพิ่มสินค้า + ตัวเลือก
  bool addToCart(
    Product product, {
    ProductVariant? selectedVariant,
  }) {
    if (product.stockQuantity < 1) return false;
    final index = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedVariant?.id == selectedVariant?.id,
    );

    if (index != -1) {
      if (_items[index].quantity >= product.stockQuantity) return false;
      _items[index].quantity++;
    } else {
      _items.add(
        CartItem(
          product: product,
          selectedVariant: selectedVariant,
        ),
      );
    }

    notifyListeners();
    return true;
  }

  // เพิ่มจำนวนของรายการที่เลือก
  bool increaseQuantity(CartItem item) {
    if (item.quantity >= item.product.stockQuantity) return false;
    item.quantity++;
    notifyListeners();
    return true;
  }

  // ลดจำนวนของรายการที่เลือก
  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }

    notifyListeners();
  }

  // ลบรายการที่เลือก
  void removeFromCart(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  // ล้างตะกร้า
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
