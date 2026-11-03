import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'owner_order_detail_screen.dart';

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _supabase
          .from('orders')
          .select('id,user_id,total_amount,status,payment_status,created_at')
          .order('created_at', ascending: false)
          .limit(100);
      if (!mounted) return;
      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleOrders => _orders.where((order) {
    final payment = order['payment_status']?.toString() ?? 'unpaid';
    final status = order['status']?.toString() ?? 'pending';
    return switch (_filter) {
      'needs_review' => payment == 'pending',
      'unpaid' => payment == 'unpaid',
      'paid' => payment == 'paid',
      'active' => status == 'pending' || status == 'confirmed',
      _ => true,
    };
  }).toList();

  String _dateLabel(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'วันที่ไม่พร้อมใช้งาน';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _paymentLabel(String? status) => switch (status) {
    'pending' => 'รอตรวจสลิป',
    'paid' => 'ชำระแล้ว',
    'unpaid' => 'ยังไม่ชำระ',
    _ => status ?? 'ไม่ทราบสถานะ',
  };

  Color _paymentColor(String? status) => switch (status) {
    'pending' => Colors.orange.shade800,
    'paid' => Colors.green.shade700,
    'unpaid' => Colors.red.shade700,
    _ => Colors.grey.shade700,
  };

  @override
  Widget build(BuildContext context) {
    final orders = _visibleOrders;
    return Scaffold(
      appBar: AppBar(
        title: const Text('คำสั่งซื้อ'),
        actions: [
          IconButton(
            tooltip: 'โหลดรายการใหม่',
            onPressed: _loading ? null : _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _filterChip('ทั้งหมด', 'all'),
                _filterChip('รอตรวจสลิป', 'needs_review'),
                _filterChip('ยังไม่ชำระ', 'unpaid'),
                _filterChip('ชำระแล้ว', 'paid'),
                _filterChip('กำลังดำเนินการ', 'active'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorState(message: _error!, onRetry: _loadOrders)
                : orders.isEmpty
                ? const Center(child: Text('ไม่มีคำสั่งซื้อในหมวดนี้'))
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final id = order['id'];
                        final payment = order['payment_status']?.toString();
                        final userId = order['user_id']?.toString() ?? '';
                        final amount = (order['total_amount'] as num?)
                                ?.toDouble() ??
                            0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            title: Text(
                              'คำสั่งซื้อ #$id',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ลูกค้า: ${_shortId(userId)}'),
                                  Text(_dateLabel(order['created_at'])),
                                  const SizedBox(height: 5),
                                  Text(
                                    _paymentLabel(payment),
                                    style: TextStyle(
                                      color: _paymentColor(payment),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '฿${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OwnerOrderDetailScreen(
                                    orderId: id,
                                  ),
                                ),
                              );
                              if (changed == true) _loadOrders();
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    ),
  );

  String _shortId(String id) => id.length > 12 ? '${id.substring(0, 8)}…' : id;
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 42),
          const SizedBox(height: 12),
          const Text('โหลดคำสั่งซื้อไม่สำเร็จ'),
          const SizedBox(height: 8),
          Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
        ],
      ),
    ),
  );
}
