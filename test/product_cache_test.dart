import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/services/product_cache.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

Map<String, dynamic> productJson({
  String id = 'cake-1',
  String name = 'Strawberry cake',
  String category = 'เค้ก',
  bool active = true,
  double price = 159,
}) => {
  'id': id,
  'name': name,
  'description': 'Fresh cream',
  'base_price': price,
  'category': category,
  'image_urls': <String>[],
  'is_active': active,
  'product_variants': <Map<String, dynamic>>[],
};

void main() {
  final cache = ProductCache.instance;

  setUpAll(() {
    ffi.sqfliteFfiInit();
    sqflite.databaseFactory = ffi.databaseFactoryFfi;
  });

  setUp(() async {
    await cache.close();
    final path = await sqflite.getDatabasesPath();
    await sqflite.deleteDatabase('$path/wongherm_cache.db');
  });

  tearDown(() => cache.close());

  test('stores products and reads them back from SQLite', () async {
    await cache.saveProducts([productJson()]);

    final products = await cache.loadProducts();

    expect(products, hasLength(1));
    expect(products.single.id, 'cake-1');
    expect(products.single.name, 'Strawberry cake');
    expect(products.single.basePrice, 159);
  });

  test('filters cached products by category', () async {
    await cache.saveProducts([
      productJson(),
      productJson(id: 'cookie-1', name: 'Cookie', category: 'คุกกี้'),
    ]);

    final products = await cache.loadProducts(category: 'คุกกี้');

    expect(products.map((product) => product.id), ['cookie-1']);
  });

  test('upserts refreshed cloud data for the same product id', () async {
    await cache.saveProducts([productJson()]);
    await cache.saveProducts([productJson(name: 'Updated cake', price: 179)]);

    final products = await cache.loadProducts();

    expect(products, hasLength(1));
    expect(products.single.name, 'Updated cake');
    expect(products.single.basePrice, 179);
  });

  test('applies successful cloud updates to cached data', () async {
    await cache.saveProducts([productJson()]);
    await cache.updateProduct('cake-1', {
      'name': 'Updated name',
      'base_price': 199.0,
      'category': 'บราวนี่',
    });

    final products = await cache.loadProducts(category: 'บราวนี่');

    expect(products.single.name, 'Updated name');
    expect(products.single.basePrice, 199);
  });

  test('removes soft-deleted products from cached catalog', () async {
    await cache.saveProducts([productJson()]);
    await cache.deactivateProduct('cake-1');

    expect(await cache.loadProducts(), isEmpty);
  });

  test('does not cache a product without an id', () async {
    final row = productJson()..remove('id');
    await cache.saveProducts([row]);

    expect(await cache.loadProducts(), isEmpty);
  });
}
