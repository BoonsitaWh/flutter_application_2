import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerOrderDetailScreen extends StatefulWidget {
  final Object orderId;

  const OwnerOrderDetailScreen({super.key, required this.orderId});

  @override
  State<OwnerOrderDetailScreen> createState() =>
      _OwnerOrderDetailScreenState();
}

class _OwnerOrderDetailScreenState extends State<OwnerOrderDetailScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _proof;
  String? _proofUrl;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final order = await _supabase
          .from('orders')
          .select('id,user_id,total_amount,status,payment_status,created_at')
          .eq('id', widget.orderId)
          .single();

      final items = await _supabase
          .from('order_items')
          .select('quantity,unit_price,subtotal,products(name)')
          .eq('order_id', widget.orderId);

      final proof = await _supabase
          .from('payment_proofs')
          .select('id,image_path,status,created_at')
          .eq('order_id', widget.orderId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      String? proofUrl;

      if (proof != null) {
        try {
          proofUrl = await _supabase.storage
              .from('payment-proofs')
              .createSignedUrl(proof['image_path'].toString(), 900);
        } catch (_) {
          // Keep order details available even if storage policy blocks the proof.
        }
      }

      if (!mounted) return;

      setState(() {
        _order = Map<String, dynamic>.from(order);
        _items = List<Map<String, dynamic>>.from(items);
        _proof = proof == null ? null : Map<String, dynamic>.from(proof);
        _proofUrl = proofUrl;
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

  Future<void> _reviewPayment({required bool approve}) async {
    final action = approve ? 'ยืนยันว่าชำระแล้ว' : 'ปฏิเสธสลิป';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text(
          approve
              ? 'ตรวจสอบยอดและข้อมูลสลิปแล้วใช่หรือไม่?'
              : 'ยืนยันปฏิเสธหลักฐานนี้หรือไม่ ลูกค้าจะต้องส่งหลักฐานใหม่',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ย้อนกลับ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      await _supabase.rpc(
        'review_payment_for_order',
        params: {
          'p_order_id': int.parse(widget.orderId.toString()),
          'p_approved': approve,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'ยืนยันการชำระเงินแล้ว' : 'ปฏิเสธสลิปแล้ว',
          ),
        ),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกผลตรวจสลิปไม่สำเร็จ: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // เปลี่ยนสถานะผ่าน RPC เพื่อให้ฐานข้อมูลตรวจสอบสิทธิ์เจ้าของร้าน
  Future<void> _setOrderStatus(String status) async {
    setState(() => _saving = true);

    try {
      await _supabase.rpc(
        'owner_update_order_status',
        params: {
          'p_order_id': int.parse(widget.orderId.toString()),
          'p_status': status,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เปลี่ยนสถานะคำสั่งซื้อสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เปลี่ยนสถานะไม่สำเร็จ: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('คำสั่งซื้อ #${widget.orderId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _orderView(),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44),
              const SizedBox(height: 12),
              const Text('โหลดรายละเอียดคำสั่งซื้อไม่สำเร็จ'),
              const SizedBox(height: 8),
              Text(
                _error!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _load,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );

  Widget _orderView() {
    final order = _order!;
    final paymentStatus =
        order['payment_status']?.toString() ?? 'unpaid';
    final orderStatus = order['status']?.toString() ?? 'pending';
    final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final canReview = _proof?['status'] == 'pending';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ลูกค้า: ${order['user_id']}'),
                const SizedBox(height: 8),
                Text('สถานะออเดอร์: ${_orderStatusLabel(orderStatus)}'),
                Text('สถานะชำระเงิน: ${_paymentLabel(paymentStatus)}'),
                const Divider(height: 24),
                Text(
                  'ยอดรวม ฿${amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'รายการสินค้า',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        if (_items.isEmpty)
          const Card(
            child: ListTile(title: Text('ไม่พบรายการสินค้า')),
          )
        else
          ..._items.map((item) {
            final product = item['products'];
            final name = product is Map
                ? product['name']?.toString() ?? 'สินค้า'
                : 'สินค้า';
            final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
            final subtotal =
                (item['subtotal'] as num?)?.toDouble() ?? 0;

            return Card(
              child: ListTile(
                title: Text(name),
                subtitle: Text('$quantity ชิ้น'),
                trailing: Text('฿${subtotal.toStringAsFixed(2)}'),
              ),
            );
          }),
        const SizedBox(height: 12),
        Text(
          'หลักฐานการชำระเงิน',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        if (_proof == null)
          const Card(
            child: ListTile(title: Text('ลูกค้ายังไม่ได้ส่งสลิป')),
          )
        else ...[
          Card(
            child: Column(
              children: [
                if (_proofUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _proofUrl!,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('เปิดรูปสลิปไม่ได้'),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('โหลดสลิปไม่ได้ ตรวจ Storage policy'),
                  ),
                ListTile(
                  title: Text(
                    'สถานะสลิป: ${_proofLabel(_proof!['status'])}',
                  ),
                  subtitle: Text(
                    'อัปโหลดเมื่อ ${_dateLabel(_proof!['created_at'])}',
                  ),
                ),
              ],
            ),
          ),
          if (canReview) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _reviewPayment(approve: false),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('ปฏิเสธสลิป'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _reviewPayment(approve: true),
                    icon: const Icon(Icons.check),
                    label: const Text('ยืนยันชำระแล้ว'),
                  ),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 20),
        Text(
          'อัปเดตสถานะออเดอร์',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statusButton('pending', 'รอดำเนินการ'),
            _statusButton('confirmed', 'ยืนยันออเดอร์'),
            _statusButton('completed', 'เสร็จสิ้น'),
            _statusButton('cancelled', 'ยกเลิก'),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _statusButton(String value, String label) => OutlinedButton(
        onPressed: _saving || _order?['status'] == value
            ? null
            : () => _setOrderStatus(value),
        child: Text(label),
      );

  String _dateLabel(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'ไม่ทราบวันที่';

    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _paymentLabel(String status) => switch (status) {
        'pending' => 'รอตรวจสอบ',
        'paid' => 'ชำระแล้ว',
        'unpaid' => 'ยังไม่ชำระ',
        _ => status,
      };

  String _proofLabel(Object? status) => switch (status?.toString()) {
        'pending' => 'รอตรวจสอบ',
        'approved' => 'อนุมัติแล้ว',
        'rejected' => 'ปฏิเสธ',
        _ => status?.toString() ?? 'ไม่ทราบสถานะ',
      };

  String _orderStatusLabel(String status) => switch (status) {
        'pending' => 'รอดำเนินการ',
        'confirmed' => 'ยืนยันแล้ว',
        'completed' => 'เสร็จสิ้น',
        'cancelled' => 'ยกเลิก',
        _ => status,
      };
}
