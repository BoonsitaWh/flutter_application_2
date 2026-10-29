import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../../cart_checkout/controllers/cart_controller.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final CartController cartController;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cartController,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // ตัวเลือกที่ลูกค้าเลือก
  ProductVariant? _selectedVariant;

  // ราคาปัจจุบัน
  double get _currentPrice {
    return widget.product.basePrice + (_selectedVariant?.additionalPrice ?? 0);
  }

  @override
  void initState() {
    super.initState();

    // ถ้ามีตัวเลือก ให้เลือกตัวแรกไว้ก่อน
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดสินค้า')),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // รูปสินค้า
            // =========================
            Container(
              width: double.infinity,
              height: 280,
              color: Colors.orange.shade50,
              child: product.imageUrls.isEmpty
                  ? const Center(
                      child: Icon(Icons.cake, size: 100, color: Colors.orange),
                    )
                  : Image.network(
                      product.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.cake,
                          size: 100,
                          color: Colors.orange,
                        ),
                      ),
                    ),
            ),

            // =========================
            // ข้อมูลสินค้า
            // =========================
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อสินค้า
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text('คงเหลือ ${product.stockQuantity} ชิ้น'),

                  const SizedBox(height: 8),

                  // ราคา
                  Text(
                    '฿${_currentPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // หมวดหมู่
                  Row(
                    children: [
                      const Icon(Icons.category, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'หมวดหมู่: ${product.category}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // รายละเอียดสินค้า
                  // =========================
                  const Text(
                    'รายละเอียดสินค้า',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    product.description?.isNotEmpty == true
                        ? product.description!
                        : 'ไม่มีรายละเอียดสินค้า',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 25),

                  // =========================
                  // ตัวเลือกสินค้า
                  // =========================
                  if (product.variants.isNotEmpty) ...[
                    const Text(
                      'เลือกตัวเลือกสินค้า',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    RadioGroup<String>(
                      groupValue: _selectedVariant?.id,
                      onChanged: (variantId) {
                        if (variantId == null) return;
                        setState(() {
                          _selectedVariant = product.variants.firstWhere(
                            (variant) => variant.id == variantId,
                          );
                        });
                      },
                      child: Column(
                        children: product.variants.map((variant) {
                          final isSelected = _selectedVariant?.id == variant.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: RadioListTile<String>(
                              value: variant.id,
                              title: Text(
                                variant.variantName,
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                variant.additionalPrice > 0
                                    ? '+฿${variant.additionalPrice.toStringAsFixed(0)}'
                                    : 'ราคาเดิม',
                              ),
                              secondary: Icon(
                                isSelected ? Icons.check_circle : Icons.tune,
                                color: isSelected
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ราคาที่เลือก
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ราคาที่เลือก: ฿${_currentPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],

                  // =========================
                  // ปุ่มเพิ่มลงตะกร้า
                  // =========================
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: product.stockQuantity < 1
                          ? null
                          : () {
                        // ถ้ามีตัวเลือก
                        // แต่ยังไม่ได้เลือก
                        if (product.variants.isNotEmpty &&
                            _selectedVariant == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('กรุณาเลือกตัวเลือกสินค้า'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final added = widget.cartController.addToCart(
                          product,
                          selectedVariant: _selectedVariant,
                        );

                        if (!added) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('สินค้าในสต๊อกไม่เพียงพอ'),
                            ),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _selectedVariant != null
                                  ? 'เพิ่ม ${product.name} (${_selectedVariant!.variantName}) ลงตะกร้าแล้ว'
                                  : 'เพิ่ม ${product.name} ลงตะกร้าแล้ว',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text(
                        'เพิ่มลงตะกร้า',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
