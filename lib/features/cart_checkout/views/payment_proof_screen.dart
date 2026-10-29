import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentProofScreen extends StatefulWidget {
  final int orderId;

  const PaymentProofScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PaymentProofScreen> createState() =>
      _PaymentProofScreenState();
}

class _PaymentProofScreenState extends State<PaymentProofScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _imageBytes;

  bool _isUploading = false;

  // =========================================
  // เลือกรูปสลิป
  // =========================================
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เลือกรูปไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================
  // อัปโหลดสลิป
  // =========================================
  Future<void> _uploadPaymentProof() async {
    if (_selectedImage == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกรูปหลักฐานการชำระเงิน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // สร้างชื่อไฟล์
      final fileName =
          '${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // เก็บไฟล์แยกตาม User
      final filePath = '${user.id}/$fileName';

      // =========================================
      // Upload ไป Supabase Storage
      // =========================================
      await _supabase.storage
          .from('payment-proofs')
          .uploadBinary(
            filePath,
            _imageBytes!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // =========================================
      // บันทึกข้อมูลลง payment_proofs
      // =========================================
      await _supabase.from('payment_proofs').insert({
        'order_id': widget.orderId,
        'user_id': user.id,
        'image_path': filePath,
        'status': 'pending',
      });

      // =========================================
      // อัปเดตสถานะการชำระเงินของ Order
      // =========================================
      await _supabase
          .from('orders')
          .update({
            'payment_status': 'pending',
          })
          .eq('id', widget.orderId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'อัปโหลดหลักฐานการชำระเงินสำเร็จ',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปโหลดไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'อัปโหลดสลิป #${widget.orderId}',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'หลักฐานการชำระเงิน',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // =========================================
            // แสดงรูปสลิป
            // =========================================
            Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageBytes == null
                  ? const Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'ยังไม่ได้เลือกสลิป',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // =========================================
            // ปุ่มเลือกรูป
            // =========================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed:
                    _isUploading ? null : _pickImage,
                icon: const Icon(
                  Icons.photo_library,
                ),
                label: const Text(
                  'เลือกรูปสลิป',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // =========================================
            // ปุ่ม Upload
            // =========================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _isUploading
                        ? null
                        : _uploadPaymentProof,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload,
                      ),
                label: Text(
                  _isUploading
                      ? 'กำลังอัปโหลด...'
                      : 'อัปโหลดหลักฐานการชำระเงิน',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}