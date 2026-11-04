// แทนตัวเลือกย่อยของสินค้า เช่น รสชาติหรือขนาดและราคาที่เพิ่ม
class ProductVariant {
  final String id;
  final String variantName;
  final double additionalPrice;

  ProductVariant({
    required this.id,
    required this.variantName,
    required this.additionalPrice,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'].toString(),
      variantName: json['variant_name'] ?? '',
      additionalPrice: (json['additional_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String? description;
  final double basePrice;
  final String category;
  final List<String> imageUrls;
  final bool isActive;

  // null = ยังไม่ได้กำหนดสต๊อก
  final int? stockQuantity;

  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.basePrice,
    required this.category,
    required this.imageUrls,
    required this.isActive,
    this.stockQuantity,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'ทั่วไป',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      isActive: json['is_active'] ?? true,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt(),
      variants: json['product_variants'] != null
          ? (json['product_variants'] as List)
                .map(
                  (v) => ProductVariant.fromJson(Map<String, dynamic>.from(v)),
                )
                .toList()
          : [],
    );
  }
}
