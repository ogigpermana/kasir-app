import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:kasir_app/core/password_utils.dart';

part 'drift_database.g.dart';

// ─── USERS & RBAC ───

class StoreSettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class UsersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get password => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text().withDefault(const Constant('kasir'))(); // admin, owner, kasir
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── STOCK ───

class StockHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(ProductsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId => integer().references(UsersTable, #id)();
  IntColumn get quantityChange => integer()(); // + or -
  IntColumn get stockBefore => integer()();
  IntColumn get stockAfter => integer()();
  TextColumn get reason => text()(); // sale, purchase, adjustment, correction
  TextColumn? get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── EXISTING TABLES ───

class CategoriesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentId => integer().nullable().references(CategoriesTable, #id, onDelete: KeyAction.setNull)();
  TextColumn get name => text().unique()();
  TextColumn? get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ProductsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().nullable().references(CategoriesTable, #id, onDelete: KeyAction.setNull)();
  TextColumn get name => text()();
  TextColumn? get barcode => text().nullable()();
  RealColumn get purchasePrice => real().withDefault(const Constant(0))();
  RealColumn get sellingPrice => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(0))();
  TextColumn? get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  IntColumn get userId => integer().references(UsersTable, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get subtotal => real()();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  RealColumn get paid => real()();
  RealColumn get change => real()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn? get note => text().nullable()();
}

class TransactionItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(TransactionsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer()();
  TextColumn get productName => text()();
  RealColumn get price => real()();
  IntColumn get quantity => integer()();
  RealColumn get subtotal => real()();
}

@DriftDatabase(
  tables: [
    StoreSettingsTable,
    UsersTable,
    CategoriesTable,
    ProductsTable,
    StockHistoryTable,
    TransactionsTable,
    TransactionItemsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({String? path}) : super(_openConnection(path));

  static String _dbName() => 'kasir_app.db';

  static QueryExecutor _openConnection(String? path) {
    if (path != null) return driftDatabase(name: path);
    return driftDatabase(name: _dbName());
  }

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(usersTable).insert(UsersTableCompanion(
        username: const Value('admin'),
        password: Value(hashPassword('admin123')),
        displayName: const Value('Administrator'),
        role: const Value('admin'),
      ));
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(stockHistoryTable);
        await m.addColumn(productsTable, productsTable.minStock);
      }
      if (from < 3) {
        await m.createTable(usersTable);
        await m.addColumn(transactionsTable, transactionsTable.userId);
      }
      if (from < 4) {
        await m.addColumn(categoriesTable, categoriesTable.parentId);
      }
      if (from < 5) {
        await m.createTable(storeSettingsTable);
      }
      if (from < 6) {
        final existing = await select(usersTable).get();
        for (final user in existing) {
          if (!isHashed(user.password)) {
            final hashed = hashPassword(user.password);
            await (update(usersTable)..where((t) => t.id.equals(user.id)))
                .write(UsersTableCompanion(password: Value(hashed)));
          }
        }
      }
    },
  );
}
