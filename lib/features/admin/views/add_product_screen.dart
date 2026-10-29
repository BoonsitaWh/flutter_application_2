import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../product/services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _variantController = TextEditingController();

  final _productService = ProductService();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'เค้ก';

  // ตัวเลือกย่อยของสินค้า
  final List<String> _variants = [];

  // รูปภาพที่เลือกจากคอมพิวเตอร์
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imageBytes = [];

  bool _isLoading = false;

  // ==========================================
  // เลือกรูปภาพสินค้า
  // ==========================================
  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();

      if (images.isEmpty) return;

      final newImages = <XFile>[];
      final newBytes = <Uint8List>[];

      for (final image in images) {
        final bytes = await image.readAsBytes();

        newImages.add(image);
        newBytes.add(bytes);
      }

      if (!mounted) return;

      setState(() {
        _selectedImages.addAll(newImages);
        _imageBytes.addAll(newBytes);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เลือกรูปไม่สำเร็จ: $e')));
    }
  }

  // ==========================================
  // ลบรูปที่เลือก
  // ==========================================
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageBytes.removeAt(index);
    });
  }

  // ==========================================
  // เพิ่มตัวเลือกย่อย
  // ==========================================
  void _addVariant() {
    final value = _variantController.text.trim();

    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกตัวเลือกย่อยก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_variants.contains(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ตัวเลือกนี้มีอยู่แล้ว'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _variants.add(value);
      _variantController.clear();
    });
  }

  // ==========================================
  // ลบตัวเลือกย่อย
  // ==========================================
  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  // ==========================================
  // บันทึกสินค้าและอัปโหลดรูป
  // ==========================================
  Future<void> _submit() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final priceText = _priceController.text.trim();
    final stockQuantity = int.tryParse(_stockController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อขนม'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);

    if (price == null || !price.isFinite || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกราคาให้ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (stockQuantity == null || stockQuantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกสต๊อกเป็นจำนวนเต็มตั้งแต่ 0 ขึ้นไป')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. อัปโหลดรูปไปยัง Supabase Storage
      final imageUrls = await _productService.uploadProductImages(
        List.generate(
          _selectedImages.length,
          (index) =>
              (name: _selectedImages[index].name, bytes: _imageBytes[index]),
        ),
      );

      // 2. บันทึกสินค้าและ URL รูป
      await _productService.createProduct(
        name: name,
        description: description,
        basePrice: price,
        category: _selectedCategory,
        stockQuantity: stockQuantity,
        variants: _variants,
        imageUrls: imageUrls,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มสินค้าสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เพิ่มสินค้าไม่สำเร็จ: $e'),
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
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _variantController.dispose();
    super.dispose();
  }

  // ==========================================
  // UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มสินค้าใหม่ (Admin)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ชื่อขนม
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อขนม',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'จำนวนคงเหลือในสต๊อก',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // รายละเอียดส่วนผสม
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดส่วนผสม',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // ราคา
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'ราคาเริ่มต้น (บาท)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // หมวดหมู่
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'เค้ก', child: Text('เค้ก')),
                  DropdownMenuItem(value: 'คุกกี้', child: Text('คุกกี้')),
                  DropdownMenuItem(value: 'บราวนี่', child: Text('บราวนี่')),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
              ),

              const SizedBox(height: 20),

              // รูปภาพสินค้า
              const Text(
                'รูปภาพสินค้า',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('เลือกรูปจากคอมพิวเตอร์'),
              ),

              const SizedBox(height: 12),

              if (_imageBytes.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_imageBytes.length, (index) {
                    return SizedBox(
                      width: 110,
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _imageBytes[index],
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _removeImage(index),
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _selectedImages[index].name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 20),

              // ตัวเลือกย่อย
              const Text(
                'ตัวเลือกย่อย (เช่น สี, ขนาด, ความหวาน):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _variantController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addVariant(),
                      decoration: const InputDecoration(
                        hintText: 'เช่น สีช็อกโกแลต / 1 ปอนด์',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _addVariant,
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.orange,
                      size: 38,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_variants.isNotEmpty)
                Column(
                  children: List.generate(_variants.length, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _variants[index],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            onPressed: _isLoading
                                ? null
                                : () => _removeVariant(index),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 24),

              // ปุ่มบันทึก
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('กำลังบันทึกสินค้า...'),
                          ],
                        )
                      : const Text(
                          'บันทึกสินค้า',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
