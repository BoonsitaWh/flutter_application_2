// แสดง แบ่งหมวด และค้นหาสินค้า รวมถึงเครื่องมือจัดการสินค้าเจ้าของร้าน
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../../admin/views/add_product_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/views/profile_screen.dart';
import '../../cart_checkout/controllers/cart_controller.dart';
import '../../cart_checkout/views/cart_screen.dart';
import '../../cart_checkout/views/order_history_screen.dart';
import 'product_detail_screen.dart';
import '../../notifications/views/notification_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/views/admin_chat_inbox_screen.dart';
import '../../chat/views/chat_screen.dart';

class ProductListScreen extends StatefulWidget {
  final bool isOwner;

  const ProductListScreen({super.key, this.isOwner = false});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final CartController _cartController = CartController();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'ทั้งหมด';

  final List<String> _categories = ['ทั้งหมด', 'เค้ก', 'คุกกี้', 'บราวนี่'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _cartController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // =========================
  // โหลดรายการสินค้า
  // =========================
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final items = await _productService.getProducts(
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() => _products = items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โหลดข้อมูลล้มเหลว: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================
  // แก้ไขสินค้า
  // =========================
  Future<void> _showEditProductDialog(Product product) async {
    final picker = ImagePicker();
    // URL ที่เก็บไว้จะคงอยู่กับสินค้า ส่วนไฟล์ใหม่จะรออัปโหลดตอนกดบันทึก
    final keptImageUrls = List<String>.from(product.imageUrls);
    final selectedImages = <XFile>[];
    final selectedImageBytes = <Uint8List>[];
    final nameController = TextEditingController(text: product.name);

    final descriptionController = TextEditingController(
      text: product.description ?? '',
    );

    final priceController = TextEditingController(
      text: product.basePrice.toString(),
    );
    final stockController = TextEditingController(
      text: product.stockQuantity.toString(),
    );

    String selectedCategory = _categories.contains(product.category)
        ? product.category
        : 'เค้ก';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('แก้ไขสินค้า'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'รูปสินค้า',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 280,
                      height: 88,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // แสดงรูปเดิมและรูปที่เลือกใหม่ พร้อมนำแต่ละรูปออกได้
                          for (
                            var index = 0;
                            index < keptImageUrls.length;
                            index++
                          )
                            _EditProductImageTile(
                              image: Image.network(
                                keptImageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                              onRemove: () => setDialogState(
                                () => keptImageUrls.removeAt(index),
                              ),
                            ),
                          for (
                            var index = 0;
                            index < selectedImageBytes.length;
                            index++
                          )
                            _EditProductImageTile(
                              image: Image.memory(
                                selectedImageBytes[index],
                                fit: BoxFit.cover,
                              ),
                              onRemove: () => setDialogState(() {
                                selectedImageBytes.removeAt(index);
                                selectedImages.removeAt(index);
                              }),
                            ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                // เลือกรูปได้หลายไฟล์และอ่าน bytes เพื่ออัปโหลดภายหลัง
                                final picked = await picker.pickMultiImage();
                                if (picked.isEmpty) return;
                                final bytes = <Uint8List>[];
                                for (final file in picked) {
                                  bytes.add(await file.readAsBytes());
                                }
                                if (!context.mounted) return;
                                setDialogState(() {
                                  selectedImages.addAll(picked);
                                  selectedImageBytes.addAll(bytes);
                                });
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('เลือกรูปไม่สำเร็จ: $error'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: const Text('เพิ่มรูป'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อสินค้า',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียดสินค้า',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'ราคา (บาท)',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'จำนวนคงเหลือในสต๊อก',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'หมวดหมู่',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .where((category) => category != 'ทั้งหมด')
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('ยกเลิก'),
                ),

                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('กรุณากรอกชื่อสินค้า'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final price = double.tryParse(
                            priceController.text.trim(),
                          );
                          final stockQuantity = int.tryParse(
                            stockController.text.trim(),
                          );

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
                              const SnackBar(
                                content: Text(
                                  'กรุณากรอกสต๊อกเป็นจำนวนเต็มตั้งแต่ 0 ขึ้นไป',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            // อัปโหลดไฟล์ใหม่ก่อน แล้วรวม URL กับรูปเดิมที่ยังเลือกไว้
                            final uploadedImageUrls = await _productService
                                .uploadProductImages(
                                  List.generate(
                                    selectedImages.length,
                                    (index) => (
                                      name: selectedImages[index].name,
                                      bytes: selectedImageBytes[index],
                                    ),
                                  ),
                                );
                            await _productService.updateProduct(
                              productId: product.id,
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              basePrice: price,
                              category: selectedCategory,
                              stockQuantity: stockQuantity,
                              imageUrls: [
                                ...keptImageUrls,
                                ...uploadedImageUrls,
                              ],
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('แก้ไขสินค้าสำเร็จ'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              await _loadProducts();
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('แก้ไขสินค้าไม่สำเร็จ: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  // =========================
  // ยืนยันการลบสินค้า
  // =========================
  Future<void> _confirmDeleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการลบสินค้า'),
          content: Text('คุณต้องการลบ "${product.name}" ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('ยกเลิก'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('ลบสินค้า'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await _productService.deleteProduct(product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบสินค้าสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบสินค้าไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wongherm Bakery'),
        actions: [
          IconButton(
            tooltip: widget.isOwner ? 'ข้อความจากลูกค้า' : 'แชทกับแอดมิน',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: _openChat,
          ),
          // =========================
          // ปุ่มตะกร้าสินค้า
          // =========================
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'การแจ้งเตือน',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          if (!widget.isOwner)
            AnimatedBuilder(
              animation: _cartController,
              builder: (context, _) {
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart),
                      if (_cartController.itemCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_cartController.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'ตะกร้าสินค้า',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CartScreen(cartController: _cartController),
                      ),
                    );
                  },
                );
              },
            ),

          PopupMenuButton<String>(
            tooltip: 'เมนูเพิ่มเติม',
            onSelected: (value) {
              switch (value) {
                case 'orders':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
                  );
                  break;
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  break;
                case 'logout':
                  _authService.signOut();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'orders',
                child: ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text('ประวัติการสั่งซื้อ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('โปรไฟล์'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('ออกจากระบบ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),

      // =========================
      // ปุ่มเพิ่มสินค้า
      // =========================
      floatingActionButton: widget.isOwner
          ? FloatingActionButton(
              tooltip: 'เพิ่มสินค้า',
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );

                if (res == true) {
                  _loadProducts();
                }
              },
            )
          : null,

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'ค้นหาสินค้า',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'ล้างคำค้นหา',
                        onPressed: () => setState(_searchController.clear),
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // =========================
          // Category Selector
          // =========================
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (value) {
                      if (value) {
                        setState(() {
                          _selectedCategory = cat;
                        });

                        _loadProducts();
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // =========================
          // Product Grid
          // =========================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _visibleProducts.isEmpty
                ? const Center(child: Text('ไม่พบรายการขนม'))
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),

                      // ⭐ แก้ปัญหา RenderFlex overflow
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 190,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),

                      itemCount: _visibleProducts.length,

                      itemBuilder: (context, index) {
                        final p = _visibleProducts[index];

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: p,
                                  cartController: _cartController,
                                  isOwner: widget.isOwner,
                                ),
                              ),
                            );
                          },

                          child: Card(
                            clipBehavior: Clip.antiAlias,

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // =========================
                                // รูปสินค้า + เมนู
                                // =========================
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 223, 228, 223),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),

                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: p.imageUrls.isEmpty
                                              ? const Center(
                                                  child: Icon(
                                                    Icons.cake,
                                                    size: 48,
                                                    color: Colors.orange,
                                                  ),
                                                )
                                              : Image.network(
                                                  p.imageUrls.first,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      const Center(
                                                        child: Icon(
                                                          Icons.cake,
                                                          size: 48,
                                                          color: Colors.orange,
                                                        ),
                                                      ),
                                                ),
                                        ),

                                        // =========================
                                        // ปุ่มแก้ไข / ลบ
                                        // =========================
                                        if (widget.isOwner)
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _showEditProductDialog(p);
                                                }

                                                if (value == 'delete') {
                                                  _confirmDeleteProduct(p);
                                                }
                                              },
                                              itemBuilder: (context) {
                                                return const [
                                                  PopupMenuItem<String>(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit),
                                                        SizedBox(width: 8),
                                                        Text('แก้ไขสินค้า'),
                                                      ],
                                                    ),
                                                  ),

                                                  PopupMenuItem<String>(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('ลบสินค้า'),
                                                      ],
                                                    ),
                                                  ),
                                                ];
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // =========================
                                // ข้อมูลสินค้า
                                // =========================
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ชื่อสินค้า
                                      Text(
                                        p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // ราคา
                                      Text(
                                        '฿${p.basePrice.toStringAsFixed(0)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),

                                      // สถานะสต๊อก
                                      Text(
                                        p.stockQuantity == null
                                            ? 'ยังไม่ได้ระบุจำนวนสต๊อก'
                                            : p.stockQuantity! > 0
                                            ? 'คงเหลือ ${p.stockQuantity} ชิ้น'
                                            : 'สินค้าหมด',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: p.stockQuantity == null
                                              ? Colors.grey
                                              : p.stockQuantity! > 0
                                              ? Colors.green.shade700
                                              : Colors.red,
                                        ),
                                      ),

                                      // จำนวนตัวเลือก
                                      if (p.variants.isNotEmpty)
                                        Text(
                                          '${p.variants.length} ตัวเลือกย่อย',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),

                                      if (!widget.isOwner)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints.tightFor(
                                                  width: 44,
                                                  height: 44,
                                                ),
                                            icon: const Icon(
                                              Icons.add_shopping_cart,
                                            ),
                                            tooltip: 'เพิ่มลงตะกร้า',
                                            onPressed:
                                                p.stockQuantity != null &&
                                                    p.stockQuantity! <= 0
                                                ? null
                                                : () {
                                                    final added =
                                                        _cartController
                                                            .addToCart(p);

                                                    if (!added) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'สินค้าในสต๊อกไม่เพียงพอ',
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'เพิ่ม ${p.name} ลงตะกร้าแล้ว',
                                                        ),
                                                        duration:
                                                            const Duration(
                                                              seconds: 1,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Future<void> _openChat() async {
    try {
      if (widget.isOwner) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminChatInboxScreen()),
        );
        return;
      }
      final conversationId = await ChatService()
          .getOrCreateCustomerConversation();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: conversationId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เปิดแชทไม่ได้: $error')));
    }
  }

  List<Product> get _visibleProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _products;
    return _products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          (product.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
}

class _EditProductImageTile extends StatelessWidget {
  final Widget image;
  final VoidCallback onRemove;

  const _EditProductImageTile({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filledTonal(
              onPressed: onRemove,
              tooltip: 'เอารูปออก',
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  );
}
