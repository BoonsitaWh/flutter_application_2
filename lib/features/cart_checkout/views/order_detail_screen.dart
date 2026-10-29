import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment_proof_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _orderItems = [];

  // ข้อมูลหลักฐานการชำระเงิน
  Map<String, dynamic>? _paymentProof;
  String? _paymentProofUrl;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    try {
      // =========================
      // โหลดข้อมูลคำสั่งซื้อ
      // =========================
      final orderResponse = await _supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .single();

      // =========================
      // โหลดรายการสินค้า
      // =========================
      final itemsResponse = await _supabase
          .from('order_items')
          .select('''
            id,
            quantity,
            unit_price,
            subtotal,
            products (
              id,
              name,
              base_price
            )
          ''')
          .eq('order_id', widget.orderId);

      // =========================
      // โหลดหลักฐานการชำระเงิน
      // =========================
      final paymentResponse = await _supabase
          .from('payment_proofs')
          .select()
          .eq('order_id', widget.orderId)
          .order('created_at', ascending: false)
          .limit(1);

      Map<String, dynamic>? paymentProof;
      String? paymentProofUrl;

      if (paymentResponse.isNotEmpty) {
        paymentProof =
            Map<String, dynamic>.from(paymentResponse.first);

        final imagePath = paymentProof['image_path'];

        if (imagePath != null && imagePath.toString().isNotEmpty) {
          paymentProofUrl = await _supabase.storage
              .from('payment-proofs')
              .createSignedUrl(
                imagePath.toString(),
                60 * 60,
              );
        }
      }

      if (!mounted) return;

      setState(() {
        _order = Map<String, dynamic>.from(orderResponse);
        _orderItems =
            List<Map<String, dynamic>>.from(itemsResponse);

        _paymentProof = paymentProof;
        _paymentProofUrl = paymentProofUrl;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'โหลดรายละเอียดคำสั่งซื้อไม่สำเร็จ: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

  String _paymentStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'ชำระเงินแล้ว';
      case 'unpaid':
        return 'ยังไม่ชำระเงิน';
      default:
        return status;
    }
  }

  // แปลงสถานะของหลักฐานการชำระเงิน
  String _paymentProofStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอตรวจสอบ';
      case 'approved':
        return 'ตรวจสอบแล้ว';
      case 'rejected':
        return 'ไม่ผ่านการตรวจสอบ';
      default:
        return status;
    }
  }

  Color _paymentProofStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String date) {
    final dt = DateTime.parse(date).toLocal();

    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายละเอียดคำสั่งซื้อ #${widget.orderId}',
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _order == null
              ? const Center(
                  child: Text('ไม่พบข้อมูลคำสั่งซื้อ'),
                )
              : _buildOrderDetail(),
    );
  }

  Widget _buildOrderDetail() {
    final order = _order!;

    final double totalAmount =
        (order['total_amount'] as num).toDouble();

    final String status =
        order['status'] ?? 'pending';

    final String paymentStatus =
        order['payment_status'] ?? 'unpaid';

    final String createdAt =
        order['created_at'] ?? '';

    return RefreshIndicator(
      onRefresh: _loadOrderDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =========================
          // ข้อมูลคำสั่งซื้อ
          // =========================
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'คำสั่งซื้อ #${widget.orderId}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text('สถานะ: '),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status)
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusText(status),
                          style: TextStyle(
                            color:
                                _statusColor(status),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'การชำระเงิน: '
                    '${_paymentStatusText(paymentStatus)}',
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'วันที่สั่งซื้อ: '
                    '${_formatDate(createdAt)}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // =========================
          // รายการสินค้า
          // =========================
          const Text(
            'รายการสินค้า',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          if (_orderItems.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'ไม่พบรายการสินค้า',
                  ),
                ),
              ),
            ),

          ..._orderItems.map(
            (item) {
              final product =
                  item['products']
                      as Map<String, dynamic>?;

              final String productName =
                  product?['name'] ?? 'สินค้า';

              final int quantity =
                  item['quantity'] ?? 0;

              final double unitPrice =
                  (item['unit_price'] as num)
                      .toDouble();

              final double subtotal =
                  (item['subtotal'] as num)
                      .toDouble();

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color:
                              Colors.orange.shade50,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cake,
                          color: Colors.orange,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              '฿${unitPrice.toStringAsFixed(2)} × $quantity',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '฿${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // =========================
          // ยอดรวม
          // =========================
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดรวมทั้งหมด',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    '฿${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // =========================
          // หลักฐานการชำระเงิน
          // =========================
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'หลักฐานการชำระเงิน',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ถ้ามีหลักฐานแล้ว
                  if (_paymentProof != null) ...[
                    Row(
                      children: [
                        const Text(
                          'สถานะ: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _paymentProofStatusColor(
                              _paymentProof!['status'] ??
                                  'pending',
                            ).withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            _paymentProofStatusText(
                              _paymentProof!['status'] ??
                                  'pending',
                            ),
                            style: TextStyle(
                              color:
                                  _paymentProofStatusColor(
                                _paymentProof!['status'] ??
                                    'pending',
                              ),
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // แสดงรูปสลิป
                    if (_paymentProofUrl != null)
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12),
                        child: Image.network(
                          _paymentProofUrl!,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          loadingBuilder:
                              (
                                context,
                                child,
                                loadingProgress,
                              ) {
                            if (loadingProgress ==
                                null) {
                              return child;
                            }

                            return const SizedBox(
                              height: 300,
                              child: Center(
                                child:
                                    CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder:
                              (
                                context,
                                error,
                                stackTrace,
                              ) {
                            return const SizedBox(
                              height: 200,
                              child: Center(
                                child: Text(
                                  'ไม่สามารถแสดงรูปสลิปได้',
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Text(
                        'ไม่สามารถโหลดรูปสลิปได้',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                  ]

                  // ถ้ายังไม่มีหลักฐาน
                  else ...[
                    const Text(
                      'ยังไม่มีการส่งหลักฐานการชำระเงิน',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result =
                              await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PaymentProofScreen(
                                orderId:
                                    widget.orderId,
                              ),
                            ),
                          );

                          if (result == true) {
                            _loadOrderDetail();
                          }
                        },
                        icon: const Icon(
                          Icons.upload_file,
                        ),
                        label: const Text(
                          'อัปโหลดหลักฐานการชำระเงิน',
                          style:
                              TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
