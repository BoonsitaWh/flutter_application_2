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
  // สร้างคำสั่งซื้อผ่าน Supabase RPC
  // =========================================
  Future<void> _createOrder() async {
    final cart = widget.cartController;

    if (cart.items.isEmpty) {
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

    // ป้องกันการกดสั่งซื้อซ้ำ
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. สำเนารายการสินค้า
      final cartItems = List.of(cart.items);

      final List<Map<String, dynamic>> itemsPayload = [];

      for (final item in cartItems) {
        final int? productId = int.tryParse(item.product.id);

        if (productId == null || productId <= 0) {
          throw Exception('รหัสสินค้าไม่ถูกต้อง');
        }

        if (item.quantity <= 0) {
          throw Exception('จำนวนสินค้าไม่ถูกต้อง');
        }

        final int? variantId = item.selectedVariant == null
            ? null
            : int.tryParse(item.selectedVariant!.id);

        if (item.selectedVariant != null &&
            (variantId == null || variantId <= 0)) {
          throw Exception('รหัสตัวเลือกสินค้าไม่ถูกต้อง');
        }

        // ส่งเฉพาะข้อมูลที่จำเป็น
        // ไม่ส่งราคา เพราะ Supabase จะคำนวณเอง
        itemsPayload.add({
          'product_id': productId,
          'variant_id': variantId,
          'quantity': item.quantity,
        });
      }

      // เก็บยอดจากตะกร้าไว้เป็นยอดสำรองสำหรับแสดงผล
      final double fallbackTotal = cartItems.fold<double>(
        0,
        (total, item) => total + item.totalPrice,
      );

      // 2. เรียก Function create_order_with_stock
      final dynamic response = await _supabase.rpc(
        'create_order_with_stock',
        params: {
          'p_items': itemsPayload,
        },
      );

      final int orderId = response is int
          ? response
          : int.parse(response.toString());

      if (orderId <= 0) {
        throw Exception('ไม่ได้รับเลขที่คำสั่งซื้อที่ถูกต้อง');
      }

      // 3. ล้างตะกร้าเมื่อสร้างคำสั่งซื้อสำเร็จ
      cart.clearCart();

      if (!mounted) return;

      // 4. อ่านยอดรวมจริงจากฐานข้อมูล
      double orderTotal = fallbackTotal;

      try {
        final orderData = await _supabase
            .from('orders')
            .select('total_amount')
            .eq('id', orderId)
            .eq('user_id', user.id)
            .single();

        orderTotal = (orderData['total_amount'] as num).toDouble();
      } catch (e) {
        // หากอ่านยอดรวมไม่ได้ คำสั่งซื้อยังสร้างสำเร็จแล้ว
        debugPrint('อ่านยอดคำสั่งซื้อไม่สำเร็จ: $e');
      }

      if (!mounted) return;

      // 5. แจ้งว่าสั่งซื้อสำเร็จ
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('สั่งซื้อสำเร็จ 🎉'),
            content: Text(
              'เลขที่คำสั่งซื้อ: #$orderId\n'
              'ยอดรวม: ฿${orderTotal.toStringAsFixed(2)}',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // 6. ไปหน้าอัปโหลดหลักฐานการชำระเงิน
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
          duration: const Duration(seconds: 5),
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

  // =========================================
  // หน้าจอ Checkout
  // =========================================
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
                        'ตัวเลือก: '
                        '${item.selectedVariant?.variantName ?? 'ไม่มี'}\n'
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
