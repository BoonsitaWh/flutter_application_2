// อ่าน เพิ่ม แก้ไข และซ่อนสินค้า พร้อมซิงก์ข้อมูลกับ Supabase และแคชในเครื่อง
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/features/product/models/product_model.dart';
import 'package:flutter_application_1/core/services/product_cache.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =========================
  // READ
  // =========================
  Future<List<Product>> getProducts({String? category}) async {
    try {
      var query = _supabase.from('products').select('*, product_variants(*)');

      if (category != null && category != 'ทั้งหมด') {
        query = query.eq('category', category);
      }

      final response = await query
          .eq('is_active', true)
          .order('created_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(response);

      try {
        await ProductCache.instance.saveProducts(rows);
      } catch (cacheError) {
        debugPrint('Product cache write failed: $cacheError');
      }

      return rows.map(Product.fromJson).toList();
    } catch (remoteError, stackTrace) {
      try {
        final cached = await ProductCache.instance.loadProducts(
          category: category,
        );
        if (cached.isNotEmpty) return cached;
      } catch (cacheError) {
        debugPrint('Product cache read failed: $cacheError');
      }

      Error.throwWithStackTrace(remoteError, stackTrace);
    }
  }

  // =========================
  // UPLOAD PRODUCT IMAGES
  // =========================
  Future<List<String>> uploadProductImages(
    List<({String name, Uint8List bytes})> images,
  ) async {
    // อัปโหลดทีละไฟล์และคืน public URL เพื่อนำไปบันทึกไว้กับสินค้า
    final urls = <String>[];

    for (final image in images) {
      final originalName = image.name;
      final extension = originalName.contains('.')
          ? originalName.split('.').last.toLowerCase()
          : 'jpg';

      final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('รองรับเฉพาะไฟล์ JPG, PNG และ WebP');
      }

      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final filePath = '$timestamp.$extension';
      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      await _supabase.storage
          .from('product-images')
          .uploadBinary(
            filePath,
            image.bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      urls.add(_supabase.storage.from('product-images').getPublicUrl(filePath));
    }

    return urls;
  }

  // =========================
  // CREATE (Product + Variant + Images)
  // =========================
  Future<void> createProduct({
    required String name,
    required String description,
    required double basePrice,
    required String category,
    required int stockQuantity,
    required List<String> variants,
    List<String> imageUrls = const [],
  }) async {
    // บันทึกข้อมูลสินค้าและตัวเลือกย่อยก่อนซิงก์สำเนาลงแคชในเครื่อง
    // ตรวจสอบบัญชีที่กำลังเข้าสู่ระบบ
    debugPrint('CURRENT USER ID: ${_supabase.auth.currentUser?.id}');
    debugPrint('CURRENT USER EMAIL: ${_supabase.auth.currentUser?.email}');

    final productData = await _supabase
        .from('products')
        .insert({
          'name': name,
          'description': description,
          'base_price': basePrice,
          'category': category,
          'stock_quantity': stockQuantity,
          'image_urls': imageUrls,
        })
        .select()
        .single();

    final productId = productData['id'];

    if (variants.isNotEmpty) {
      final variantData = variants
          .map(
            (v) => {
              'product_id': productId,
              'variant_name': v,
              'additional_price': 0.0,
            },
          )
          .toList();

      await _supabase.from('product_variants').insert(variantData);
    }

    await _updateCacheSafely(
      () => ProductCache.instance.saveProducts([
        {
          ...Map<String, dynamic>.from(productData),
          'product_variants': variants
              .map(
                (name) => {
                  'id': 'local-$name',
                  'variant_name': name,
                  'additional_price': 0.0,
                },
              )
              .toList(),
        },
      ]),
    );
  }

  // =========================
  // UPDATE
  // =========================
  Future<void> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double basePrice,
    required String category,
    required int stockQuantity,
    required List<String> imageUrls,
  }) async {
    // อัปเดตทั้งฐานข้อมูลบนคลาวด์และแคช เพื่อให้หน้ารายการเห็นข้อมูลล่าสุด
    await _supabase
        .from('products')
        .update({
          'name': name,
          'description': description,
          'base_price': basePrice,
          'category': category,
          'stock_quantity': stockQuantity,
          'image_urls': imageUrls,
        })
        .eq('id', productId);

    await _updateCacheSafely(
      () => ProductCache.instance.updateProduct(productId, {
        'name': name,
        'description': description,
        'base_price': basePrice,
        'category': category,
        'stock_quantity': stockQuantity,
        'image_urls': imageUrls,
      }),
    );
  }

  // =========================
  // DELETE (Soft Delete)
  // =========================
  Future<void> deleteProduct(String productId) async {
    await _supabase
        .from('products')
        .update({'is_active': false})
        .eq('id', productId);

    await _updateCacheSafely(
      () => ProductCache.instance.deactivateProduct(productId),
    );
  }

  Future<void> _updateCacheSafely(Future<void> Function() update) async {
    try {
      await update();
    } catch (error) {
      debugPrint('Product cache update failed: $error');
    }
  }
}
