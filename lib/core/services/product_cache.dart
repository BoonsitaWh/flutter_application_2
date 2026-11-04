// จัดการแคชรายการสินค้าใน SQLite เพื่อเปิดดูข้อมูลที่โหลดไว้ได้
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../features/product/models/product_model.dart';

/// SQLite read-through cache for public product catalog data.
///
/// The cloud remains authoritative. Cached catalog entries are used when the
/// network request fails, and are refreshed after successful cloud reads.
class ProductCache {
  ProductCache._();

  static final ProductCache instance = ProductCache._();
  static const _databaseName = 'wongherm_cache.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final path = await getDatabasesPath();
    _database = await openDatabase(
      '$path/$_databaseName',
      version: _databaseVersion,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE cached_products (
            id TEXT PRIMARY KEY,
            category TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            payload TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await database.execute(
          'CREATE INDEX cached_products_category_idx '
          'ON cached_products(category, is_active)',
        );
      },
    );
    return _database!;
  }

  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    if (products.isEmpty) return;

    final database = await _db;
    final batch = database.batch();
    final cachedAt = DateTime.now().toUtc().toIso8601String();

    for (final product in products) {
      final id = product['id']?.toString();
      if (id == null || id.isEmpty) continue;

      batch.insert('cached_products', {
        'id': id,
        'category': product['category']?.toString() ?? 'ทั่วไป',
        'is_active': product['is_active'] == false ? 0 : 1,
        'payload': jsonEncode(product),
        'cached_at': cachedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Product>> loadProducts({String? category}) async {
    final database = await _db;
    final where = <String>['is_active = ?'];
    final whereArgs = <Object?>[1];

    if (category != null && category != 'ทั้งหมด') {
      where.add('category = ?');
      whereArgs.add(category);
    }

    final rows = await database.query(
      'cached_products',
      columns: const ['payload'],
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'cached_at DESC',
    );

    return rows
        .map(
          (row) => Product.fromJson(
            jsonDecode(row['payload']! as String) as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> values,
  ) async {
    final database = await _db;
    final rows = await database.query(
      'cached_products',
      columns: const ['payload'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final payload =
        jsonDecode(rows.first['payload']! as String) as Map<String, dynamic>;
    payload.addAll(values);

    await database.update(
      'cached_products',
      {
        'category': payload['category']?.toString() ?? 'ทั่วไป',
        'is_active': payload['is_active'] == false ? 0 : 1,
        'payload': jsonEncode(payload),
        'cached_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> deactivateProduct(String productId) async {
    final database = await _db;
    final rows = await database.query(
      'cached_products',
      columns: const ['payload'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final payload =
        jsonDecode(rows.first['payload']! as String) as Map<String, dynamic>;
    payload['is_active'] = false;

    await database.update(
      'cached_products',
      {
        'is_active': 0,
        'payload': jsonEncode(payload),
        'cached_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
