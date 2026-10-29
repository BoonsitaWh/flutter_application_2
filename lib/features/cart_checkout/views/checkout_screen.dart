import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/cart_controller.dart';
import 'payment_proof_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final CartController cartController;

  const CheckoutScreen({
    super.key,
    required this.cartController,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;

  // =========================================
  // สร้างคำสั่งซื้อ
  // =========================================
  Future<void> _createOrder() async {
    if (widget.cartController.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีสินค้าในตะกร้า'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนสั่งซื้อ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // =========================================
      // 1. สร้าง Order
      // =========================================
      final order = await _supabase
          .from('orders')
          .insert({
            'user_id': user.id,
            'total_amount': widget.cartController.totalPrice,
            'status': 'pending',
            'payment_status': 'unpaid',
          })
          .select()
          .single();

      final int orderId = order['id'];
      final double orderTotal = widget.cartController.totalPrice;

      // =========================================
      // 2. เพิ่มสินค้าแต่ละรายการลง order_items
      // =========================================
      for (final item in widget.cartController.items) {
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'subtotal': item.totalPrice,
        });
      }

      // =========================================
      // 3. ล้างตะกร้า
      // =========================================
      widget.cartController.clearCart();

      if (!mounted) return;

      // =========================================
      // 4. แจ้งว่าสั่งซื้อสำเร็จ
      // =========================================
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('สั่งซื้อสำเร็จ 🎉'),
            content: Text(
              'เลขที่คำสั่งซื้อ: #$orderId\n'
              'ยอดรวม: ฿${orderTotal.toStringAsFixed(2)}',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // =========================================
      // 5. ไปหน้าอัปโหลดหลักฐานการชำระเงิน
      // =========================================
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentProofScreen(
            orderId: orderId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้างคำสั่งซื้อไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cartController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันคำสั่งซื้อ'),
      ),
      body: AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Text('ไม่มีสินค้าในตะกร้า'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'รายการสินค้า',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // =========================================
              // รายการสินค้า
              // =========================================
              ...cart.items.map(
                (item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.cake),
                      ),
                      title: Text(item.product.name),
                      subtitle: Text(
                        'ตัวเลือก: ${item.selectedVariant?.variantName ?? 'ไม่มี'}\n'
                        'จำนวน ${item.quantity} × '
                        '฿${item.unitPrice.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        '฿${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Divider(),

              // =========================================
              // ยอดรวม
              // =========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดรวมทั้งหมด',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '฿${cart.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // =========================================
              // ปุ่มยืนยัน
              // =========================================
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createOrder,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isLoading
                        ? 'กำลังบันทึกคำสั่งซื้อ...'
                        : 'ยืนยันคำสั่งซื้อ',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}