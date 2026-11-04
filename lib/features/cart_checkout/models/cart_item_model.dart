// เก็บสินค้าและจำนวนที่ลูกค้าเลือกไว้ในตะกร้าก่อนสั่งซื้อ
import '../../product/models/product_model.dart';

class CartItem {
  final Product product;

  // ตัวเลือกย่อยที่ลูกค้าเลือก
  final ProductVariant? selectedVariant;

  int quantity;

  CartItem({required this.product, this.selectedVariant, this.quantity = 1});

  // ราคาต่อชิ้น
  double get unitPrice {
    return product.basePrice + (selectedVariant?.additionalPrice ?? 0);
  }

  // ราคารวม
  double get totalPrice {
    return unitPrice * quantity;
  }
}
