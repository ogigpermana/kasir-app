import 'package:drift/drift.dart';
import 'package:kasir_app/core/password_utils.dart';
import 'package:kasir_app/core/session.dart';
import 'package:kasir_app/data/datasources/local/drift_database.dart';
import 'package:kasir_app/domain/entities/product.dart';
import 'package:kasir_app/domain/entities/category.dart';
import 'package:kasir_app/domain/entities/transaction.dart';
import 'package:kasir_app/domain/repositories/repositories.dart';

class UserData {
  final int id;
  final String username, displayName, role;
  final bool isActive;
  UserData({required this.id, required this.username, required this.displayName, required this.role, this.isActive = true});
}

class RepositoryImpl implements ProductRepository, TransactionRepository {
  final AppDatabase _db;
  RepositoryImpl(this._db);

  UserData? _currentUser;
  UserData? get currentUser => _currentUser;

  Future<bool> login(String username, String password) async {
    final user = await (_db.select(_db.usersTable)..where((t) => t.username.equals(username))).getSingleOrNull();
    if (user == null || !user.isActive) return false;
    if (!verifyPassword(password, user.password)) return false;
    _currentUser = UserData(id: user.id, username: user.username, displayName: user.displayName, role: user.role, isActive: user.isActive);
    await Session.saveUserId(user.id);
    return true;
  }

  Future<void> restoreSession() async {
    final userId = Session.userId;
    if (userId == null) return;
    final user = await (_db.select(_db.usersTable)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (user != null && user.isActive) {
      _currentUser = UserData(id: user.id, username: user.username, displayName: user.displayName, role: user.role, isActive: user.isActive);
    } else {
      await Session.clear();
    }
  }

  void logout() {
    _currentUser = null;
    Session.clear();
  }

  bool hasPermission(List<String> roles) => _currentUser != null && roles.contains(_currentUser!.role);

  Future<List<UserData>> getAllUsers() async {
    final rows = await _db.select(_db.usersTable).get();
    return rows.map((u) => UserData(id: u.id, username: u.username, displayName: u.displayName, role: u.role, isActive: u.isActive)).toList();
  }

  Future<void> createUser(String username, String password, String displayName, String role) async {
    await _db.into(_db.usersTable).insert(UsersTableCompanion(
      username: Value(username), password: Value(hashPassword(password)),
      displayName: Value(displayName), role: Value(role),
    ));
  }

  Future<void> updateUser(int id, {String? password, String? displayName, String? role, bool? isActive}) async {
    await (_db.update(_db.usersTable)..where((t) => t.id.equals(id))).write(UsersTableCompanion(
      password: password != null ? Value(hashPassword(password)) : Value.absent(),
      displayName: displayName != null ? Value(displayName) : Value.absent(),
      role: role != null ? Value(role) : Value.absent(),
      isActive: isActive != null ? Value(isActive) : Value.absent(),
    ));
  }

  Future<void> deleteUser(int id) async {
    await (_db.delete(_db.usersTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<Product>> getAllProducts() async {
    final rows = await _db.select(_db.productsTable).get();
    return rows.map((r) => Product(
      id: r.id, categoryId: r.categoryId, name: r.name, barcode: r.barcode,
      purchasePrice: r.purchasePrice, sellingPrice: r.sellingPrice,
      stock: r.stock, minStock: r.minStock, imagePath: r.imagePath,
      createdAt: r.createdAt, updatedAt: r.updatedAt,
    )).toList();
  }

  @override
  Future<Product?> getProductById(int id) async {
    final r = await (_db.select(_db.productsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) return null;
    return Product(id: r.id, categoryId: r.categoryId, name: r.name, barcode: r.barcode,
      purchasePrice: r.purchasePrice, sellingPrice: r.sellingPrice,
      stock: r.stock, minStock: r.minStock, imagePath: r.imagePath,
      createdAt: r.createdAt, updatedAt: r.updatedAt);
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    final r = await (_db.select(_db.productsTable)..where((t) => t.barcode.equals(barcode))).getSingleOrNull();
    if (r == null) return null;
    return Product(id: r.id, categoryId: r.categoryId, name: r.name, barcode: r.barcode,
      purchasePrice: r.purchasePrice, sellingPrice: r.sellingPrice,
      stock: r.stock, minStock: r.minStock, imagePath: r.imagePath,
      createdAt: r.createdAt, updatedAt: r.updatedAt);
  }

  @override
  Future<Product> insertProduct(Product p) async {
    final id = await _db.into(_db.productsTable).insert(ProductsTableCompanion(
      categoryId: Value<int?>(p.categoryId), name: Value(p.name),
      barcode: Value<String?>(p.barcode), purchasePrice: Value(p.purchasePrice),
      sellingPrice: Value(p.sellingPrice), stock: Value(p.stock),
      minStock: Value(p.minStock), imagePath: Value<String?>(p.imagePath),
    ));
    return p.copyWith(id: id);
  }

  @override
  Future<Product> updateProduct(Product p) async {
    await (_db.update(_db.productsTable)..where((t) => t.id.equals(p.id!))).write(ProductsTableCompanion(
      name: Value(p.name), categoryId: Value<int?>(p.categoryId),
      barcode: Value<String?>(p.barcode), purchasePrice: Value(p.purchasePrice),
      sellingPrice: Value(p.sellingPrice), stock: Value(p.stock),
      minStock: Value(p.minStock), imagePath: Value<String?>(p.imagePath),
      updatedAt: Value(DateTime.now()),
    ));
    return p;
  }

  @override
  Future<void> deleteProduct(int id) async {
    await (_db.delete(_db.productsTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> updateStock(int productId, int quantity) async {
    await adjustStock(productId, quantity, 'adjustment');
  }

  Future<List<Product>> getLowStockProducts() async {
    final rows = await _db.select(_db.productsTable).get();
    return rows.where((r) => r.stock <= r.minStock).map((r) => Product(
      id: r.id, categoryId: r.categoryId, name: r.name, barcode: r.barcode,
      purchasePrice: r.purchasePrice, sellingPrice: r.sellingPrice,
      stock: r.stock, minStock: r.minStock, imagePath: r.imagePath,
      createdAt: r.createdAt, updatedAt: r.updatedAt,
    )).toList();
  }

  Future<void> adjustStock(int productId, int quantityChange, String reason, {String? note}) async {
    final product = await getProductById(productId);
    if (product == null) return;
    final stockBefore = product.stock;
    final stockAfter = stockBefore + quantityChange;
    if (stockAfter < 0) {
      throw Exception('Stok tidak mencukupi. Stok saat ini: $stockBefore, permintaan: ${-quantityChange}');
    }
    await _db.into(_db.stockHistoryTable).insert(StockHistoryTableCompanion(
      productId: Value(productId), userId: Value(_currentUser?.id ?? 0),
      quantityChange: Value(quantityChange), stockBefore: Value(stockBefore),
      stockAfter: Value(stockAfter), reason: Value(reason), note: Value<String?>(note),
    ));
    await updateProduct(product.copyWith(stock: stockAfter));
  }

  Future<List<Map<String, dynamic>>> getStockHistory({int? productId}) async {
    final joined = _db.select(_db.stockHistoryTable).join([
      innerJoin(_db.productsTable, _db.productsTable.id.equalsExp(_db.stockHistoryTable.productId)),
    ]);
    joined.orderBy([OrderingTerm.desc(_db.stockHistoryTable.createdAt)]);
    final rows = await joined.get();
    var filtered = rows;
    if (productId != null) {
      filtered = rows.where((r) => r.read(_db.stockHistoryTable.productId) == productId).toList();
    }
    return filtered.map((r) => <String, dynamic>{
      'id': r.read(_db.stockHistoryTable.id),
      'productId': r.read(_db.stockHistoryTable.productId),
      'productName': r.read(_db.productsTable.name),
      'quantityChange': r.read(_db.stockHistoryTable.quantityChange),
      'stockBefore': r.read(_db.stockHistoryTable.stockBefore),
      'stockAfter': r.read(_db.stockHistoryTable.stockAfter),
      'reason': r.read(_db.stockHistoryTable.reason),
      'note': r.read(_db.stockHistoryTable.note),
      'createdAt': r.read(_db.stockHistoryTable.createdAt),
    }).toList();
  }

  @override
  Future<List<Category>> getAllCategories() async {
    final rows = await _db.select(_db.categoriesTable).get();
    return rows.map((r) => Category(id: r.id, parentId: r.parentId, name: r.name, description: r.description, createdAt: r.createdAt)).toList();
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    final r = await (_db.select(_db.categoriesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) return null;
    return Category(id: r.id, parentId: r.parentId, name: r.name, description: r.description, createdAt: r.createdAt);
  }

  @override
  Future<Category> insertCategory(Category c) async {
    final id = await _db.into(_db.categoriesTable).insert(CategoriesTableCompanion(
      name: Value(c.name), description: Value<String?>(c.description),
      parentId: Value<int?>(c.parentId),
    ));
    return c.copyWith(id: id);
  }

  @override
  Future<Category> updateCategory(Category c) async {
    await (_db.update(_db.categoriesTable)..where((t) => t.id.equals(c.id!))).write(
      CategoriesTableCompanion(name: Value(c.name), description: Value<String?>(c.description), parentId: Value<int?>(c.parentId)),
    );
    return c;
  }

  @override
  Future<void> deleteCategory(int id) async {
    await (_db.update(_db.categoriesTable)..where((t) => t.parentId.equals(id))).write(
      CategoriesTableCompanion(parentId: const Value<int?>(null)),
    );
    await (_db.delete(_db.categoriesTable)..where((t) => t.id.equals(id))).go();
  }

  List<Category> buildCategoryTree(List<Category> flat) {
    final map = <int, Category>{};
    for (final c in flat.where((c) => c.id != null)) {
      map[c.id!] = c.copyWith(children: []);
    }
    for (final c in map.values.toList()) {
      if (c.parentId != null && map.containsKey(c.parentId)) {
        map[c.parentId!] = map[c.parentId!]!.copyWith(
          children: [...(map[c.parentId!]!.children ?? []), c],
        );
      }
    }
    return map.values.where((c) => c.parentId == null).toList();
  }

  String generateBarcode() {
    final now = DateTime.now();
    final rand = now.microsecondsSinceEpoch % 10000;
    return 'BRC${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${rand.toString().padLeft(4, '0')}';
  }

  // ─── STORE SETTINGS ───
  Future<bool> isOnboardingComplete() async {
    final row = await (_db.select(_db.storeSettingsTable)..where((t) => t.key.equals('onboarding_done'))).getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> completeOnboarding(String storeName, String businessType) async {
    await _db.into(_db.storeSettingsTable).insertOnConflictUpdate(StoreSettingsTableCompanion(
      key: const Value('onboarding_done'), value: const Value('true'),
    ));
    await _db.into(_db.storeSettingsTable).insertOnConflictUpdate(StoreSettingsTableCompanion(
      key: const Value('store_name'), value: Value(storeName),
    ));
    await _db.into(_db.storeSettingsTable).insertOnConflictUpdate(StoreSettingsTableCompanion(
      key: const Value('business_type'), value: Value(businessType),
    ));
  }

  Future<String> getStoreName() async {
    final row = await (_db.select(_db.storeSettingsTable)..where((t) => t.key.equals('store_name'))).getSingleOrNull();
    return row?.value ?? 'Kasir App';
  }

  Future<String> getBusinessType() async {
    final row = await (_db.select(_db.storeSettingsTable)..where((t) => t.key.equals('business_type'))).getSingleOrNull();
    return row?.value ?? '';
  }

  Future<double> getTaxPercent() async {
    final row = await (_db.select(_db.storeSettingsTable)..where((t) => t.key.equals('tax_percent'))).getSingleOrNull();
    if (row == null) return 11;
    return double.tryParse(row.value) ?? 11;
  }

  Future<void> setTaxPercent(double value) async {
    await _db.into(_db.storeSettingsTable).insertOnConflictUpdate(StoreSettingsTableCompanion(
      key: const Value('tax_percent'), value: Value(value.toString()),
    ));
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    final rows = await _db.select(_db.transactionsTable).get();
    final result = <Transaction>[];
    for (final row in rows) {
      final items = await (_db.select(_db.transactionItemsTable)..where((t) => t.transactionId.equals(row.id))).get();
      result.add(Transaction(
        id: row.id, invoiceNumber: row.invoiceNumber, date: row.date,
        items: items.map((i) => TransactionItem(
          id: i.id, transactionId: i.transactionId, productId: i.productId,
          productName: i.productName, price: i.price, quantity: i.quantity, subtotal: i.subtotal,
        )).toList(),
        subtotal: row.subtotal, tax: row.tax, discount: row.discount,
        total: row.total, paid: row.paid, change: row.change,
        paymentMethod: row.paymentMethod, note: row.note,
      ));
    }
    return result;
  }

  @override
  Future<Transaction?> getTransactionById(int id) async {
    final row = await (_db.select(_db.transactionsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final items = await (_db.select(_db.transactionItemsTable)..where((t) => t.transactionId.equals(row.id))).get();
    return Transaction(
      id: row.id, invoiceNumber: row.invoiceNumber, date: row.date,
      items: items.map((i) => TransactionItem(
        id: i.id, transactionId: i.transactionId, productId: i.productId,
        productName: i.productName, price: i.price, quantity: i.quantity, subtotal: i.subtotal,
      )).toList(),
      subtotal: row.subtotal, tax: row.tax, discount: row.discount,
      total: row.total, paid: row.paid, change: row.change,
      paymentMethod: row.paymentMethod, note: row.note,
    );
  }

  @override
  Future<List<Transaction>> getTransactionsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final rows = await (_db.select(_db.transactionsTable)
      ..where((t) => t.date.isBetween(Variable<DateTime>(startOfDay), Variable<DateTime>(endOfDay)))).get();
    final result = <Transaction>[];
    for (final row in rows) {
      final items = await (_db.select(_db.transactionItemsTable)..where((t) => t.transactionId.equals(row.id))).get();
      result.add(Transaction(
        id: row.id, invoiceNumber: row.invoiceNumber, date: row.date,
        items: items.map((i) => TransactionItem(
          id: i.id, transactionId: i.transactionId, productId: i.productId,
          productName: i.productName, price: i.price, quantity: i.quantity, subtotal: i.subtotal,
        )).toList(),
        subtotal: row.subtotal, tax: row.tax, discount: row.discount,
        total: row.total, paid: row.paid, change: row.change,
        paymentMethod: row.paymentMethod, note: row.note,
      ));
    }
    return result;
  }

  @override
  Future<Transaction> createTransaction(Transaction t) async {
    final invoice = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    final id = await _db.into(_db.transactionsTable).insert(TransactionsTableCompanion(
      invoiceNumber: Value(invoice), userId: Value(_currentUser?.id ?? 0),
      date: Value(t.date), subtotal: Value(t.subtotal), tax: Value(t.tax),
      discount: Value(t.discount), total: Value(t.total), paid: Value(t.paid),
      change: Value(t.change), paymentMethod: Value(t.paymentMethod), note: Value<String?>(t.note),
    ));
    for (final item in t.items) {
      await _db.into(_db.transactionItemsTable).insert(TransactionItemsTableCompanion(
        transactionId: Value(id), productId: Value(item.productId),
        productName: Value(item.productName), price: Value(item.price),
        quantity: Value(item.quantity), subtotal: Value(item.subtotal),
      ));
      await adjustStock(item.productId, -item.quantity, 'sale');
    }
    return t.copyWith(id: id, invoiceNumber: invoice);
  }

  Future<String> exportTransactionsCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('Invoice,Tanggal,Item,Subtotal,Pajak,Total,Dibayar,Kembalian');
    final transactions = await getAllTransactions();
    for (final t in transactions) {
      buffer.writeln('${t.invoiceNumber},${t.date.toIso8601String()},${t.items.length},${t.subtotal},${t.tax},${t.total},${t.paid},${t.change}');
    }
    return buffer.toString();
  }
}
