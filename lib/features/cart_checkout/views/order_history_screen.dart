// โหลดและแสดงประวัติคำสั่งซื้อของลูกค้าที่เข้าสู่ระบบ
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // โหลดประวัติการสั่งซื้อของผู้ใช้ปัจจุบัน
  Future<void> _loadOrders() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('โหลดประวัติการสั่งซื้อไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // แปลงวันที่ให้อ่านง่าย
  String _formatDate(String date) {
    final dt = DateTime.parse(date).toLocal();

    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  // สีของสถานะคำสั่งซื้อ
  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'confirmed':
        return Colors.blue;

      case 'completed':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // แสดงข้อความสถานะคำสั่งซื้อภาษาไทย
  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';

      case 'confirmed':
        return 'ยืนยันแล้ว';

      case 'completed':
        return 'เสร็จสิ้น';

      case 'cancelled':
        return 'ยกเลิก';

      default:
        return status;
    }
  }

  // แสดงข้อความสถานะการชำระเงิน
  String _paymentStatusText(String paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return 'ชำระแล้ว';

      case 'unpaid':
        return 'ยังไม่ชำระ';

      default:
        return paymentStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการสั่งซื้อ')),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 70, color: Colors.grey),

                  SizedBox(height: 15),

                  Text(
                    'ยังไม่มีประวัติการสั่งซื้อ',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,

              child: ListView.builder(
                padding: const EdgeInsets.all(16),

                itemCount: _orders.length,

                itemBuilder: (context, index) {
                  final order = _orders[index];

                  // ID คำสั่งซื้อ
                  final int orderId = (order['id'] as num).toInt();

                  // ยอดรวม
                  final double totalAmount = (order['total_amount'] as num)
                      .toDouble();

                  // สถานะคำสั่งซื้อ
                  final String status = order['status'] ?? 'pending';

                  // สถานะการชำระเงิน
                  final String paymentStatus =
                      order['payment_status'] ?? 'unpaid';

                  // วันที่สั่งซื้อ
                  final String createdAt = order['created_at'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),

                    elevation: 2,

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // =========================
                          // หัวข้อคำสั่งซื้อ
                          // =========================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [
                              Text(
                                'คำสั่งซื้อ #$orderId',

                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),

                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    status,
                                  ).withValues(alpha: 0.15),

                                  borderRadius: BorderRadius.circular(20),
                                ),

                                child: Text(
                                  _statusText(status),

                                  style: TextStyle(
                                    color: _statusColor(status),

                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // =========================
                          // ยอดรวม
                          // =========================
                          Text(
                            'ยอดรวม: ฿${totalAmount.toStringAsFixed(2)}',

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // =========================
                          // สถานะการชำระเงิน
                          // =========================
                          Text(
                            'สถานะการชำระเงิน: '
                            '${_paymentStatusText(paymentStatus)}',
                          ),

                          const SizedBox(height: 6),

                          // =========================
                          // วันที่สั่งซื้อ
                          // =========================
                          Text(
                            'วันที่สั่งซื้อ: '
                            '${_formatDate(createdAt)}',

                            style: const TextStyle(color: Colors.grey),
                          ),

                          const SizedBox(height: 12),

                          // =========================
                          // ปุ่มรายละเอียดคำสั่งซื้อ
                          // =========================
                          SizedBox(
                            width: double.infinity,

                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,

                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderDetailScreen(orderId: orderId),
                                  ),
                                );
                              },

                              icon: const Icon(Icons.receipt_long),

                              label: const Text(
                                'รายละเอียดคำสั่งซื้อ',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
