import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final CartController cartController;

  const CartScreen({super.key, required this.cartController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartController,
      builder: (context, _) {
        final items = cartController.items;

        return Scaffold(
          appBar: AppBar(title: const Text('🛒 ตะกร้าสินค้า')),
          body: items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'ยังไม่มีสินค้าในตะกร้า',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final product = item.product;
                          final variant = item.selectedVariant;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 300;

                                final productInfo = Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      softWrap: true,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (variant != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'ตัวเลือก: ${variant.variantName}',
                                        softWrap: true,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 5),
                                    Text(
                                      'ราคาต่อชิ้น ฿${item.unitPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );

                                final productImage = Container(
                                  width: 65,
                                  height: 65,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.cake,
                                    size: 38,
                                    color: Colors.orange,
                                  ),
                                );

                                final quantityControls = Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'ลดจำนวน',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        cartController.decreaseQuantity(item);
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'เพิ่มจำนวน',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        cartController.increaseQuantity(item);
                                      },
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                  ],
                                );

                                final totalAndDelete = Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '฿${item.totalPrice.toStringAsFixed(0)}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'ลบสินค้า',
                                      onPressed: () {
                                        cartController.removeFromCart(item);
                                      },
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                );

                                return Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: isNarrow
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Center(child: productImage),
                                            const SizedBox(height: 10),
                                            productInfo,
                                            const Divider(height: 20),
                                            Wrap(
                                              alignment:
                                                  WrapAlignment.spaceBetween,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                quantityControls,
                                                totalAndDelete,
                                              ],
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            Row(
                                              children: [
                                                productImage,
                                                const SizedBox(width: 12),
                                                Expanded(child: productInfo),
                                              ],
                                            ),
                                            const Divider(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                quantityControls,
                                                totalAndDelete,
                                              ],
                                            ),
                                          ],
                                        ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'จำนวนสินค้า',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${cartController.itemCount} ชิ้น',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ราคารวม',
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                '฿${cartController.totalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(
                                      cartController: cartController,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.shopping_cart_checkout),
                              label: const Text(
                                'ดำเนินการสั่งซื้อ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
