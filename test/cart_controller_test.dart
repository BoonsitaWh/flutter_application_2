// ทดสอบการเพิ่ม ปรับจำนวน ลบสินค้า และคำนวณยอดรวมของตะกร้า
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/cart_checkout/controllers/cart_controller.dart';
import 'package:flutter_application_1/features/product/models/product_model.dart';

Product product(String id, {double price = 20}) => Product(
  id: id,
  name: 'Bakery $id',
  description: null,
  basePrice: price,
  category: 'เค้ก',
  imageUrls: const [],
  isActive: true,
  variants: const [],
);

void main() {
  group('CartController', () {
    test('1. starts empty with zero totals', () {
      final cart = CartController();
      expect(cart.items, isEmpty);
      expect(cart.itemCount, 0);
      expect(cart.totalPrice, 0);
      cart.dispose();
    });

    test('2. adds one product with quantity one', () {
      final cart = CartController()..addToCart(product('a'));
      expect(cart.items, hasLength(1));
      expect(cart.itemCount, 1);
      expect(cart.totalPrice, 20);
      cart.dispose();
    });

    test('3. adding same product increments existing line', () {
      final cart = CartController()
        ..addToCart(product('a'))
        ..addToCart(product('a'));
      expect(cart.items, hasLength(1));
      expect(cart.items.single.quantity, 2);
      cart.dispose();
    });

    test('4. different products stay on separate lines', () {
      final cart = CartController()
        ..addToCart(product('a'))
        ..addToCart(product('b'));
      expect(cart.items, hasLength(2));
      cart.dispose();
    });

    test('5. item count sums quantities across lines', () {
      final cart = CartController()..addToCart(product('a'));
      cart.increaseQuantity(cart.items.single);
      cart.addToCart(product('b'));
      expect(cart.itemCount, 3);
      cart.dispose();
    });

    test('6. total price sums line subtotals', () {
      final cart = CartController()
        ..addToCart(product('a', price: 20))
        ..addToCart(product('b', price: 35));
      expect(cart.totalPrice, 55);
      cart.dispose();
    });

    test('7. increasing quantity updates total', () {
      final cart = CartController()..addToCart(product('a'));
      cart.increaseQuantity(cart.items.single);
      expect(cart.totalPrice, 40);
      cart.dispose();
    });

    test('8. decreasing quantity above one decrements it', () {
      final cart = CartController()..addToCart(product('a'));
      final item = cart.items.single;
      cart.increaseQuantity(item);
      cart.decreaseQuantity(item);
      expect(item.quantity, 1);
      expect(cart.items, hasLength(1));
      cart.dispose();
    });

    test('9. decreasing quantity at one removes the line', () {
      final cart = CartController()..addToCart(product('a'));
      cart.decreaseQuantity(cart.items.single);
      expect(cart.items, isEmpty);
      cart.dispose();
    });

    test('10. removeFromCart removes only the selected line', () {
      final cart = CartController()
        ..addToCart(product('a'))
        ..addToCart(product('b'));
      cart.removeFromCart(cart.items.first);
      expect(cart.items, hasLength(1));
      expect(cart.items.single.product.id, 'b');
      cart.dispose();
    });

    test('11. clearCart empties items and resets totals', () {
      final cart = CartController()
        ..addToCart(product('a'))
        ..addToCart(product('b'));
      cart.clearCart();
      expect(cart.items, isEmpty);
      expect(cart.itemCount, 0);
      expect(cart.totalPrice, 0);
      cart.dispose();
    });

    test('12. items getter cannot mutate internal list', () {
      final cart = CartController()..addToCart(product('a'));
      expect(() => cart.items.clear(), throwsUnsupportedError);
      expect(cart.items, hasLength(1));
      cart.dispose();
    });
  });
}
