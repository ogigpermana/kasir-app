import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_app/core/session.dart';
import 'package:kasir_app/data/datasources/local/drift_database.dart';
import 'package:kasir_app/data/repositories/repository_impl.dart';
import 'package:kasir_app/domain/entities/product.dart';
import 'package:kasir_app/domain/entities/category.dart';
import 'package:kasir_app/domain/entities/transaction.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void add(Product product) {
    final idx = state.indexWhere((c) => c.product.id == product.id);
    if (idx >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx) CartItem(product: product, quantity: state[i].quantity + 1) else state[i],
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeAt(int index) {
    state = [...state]..removeAt(index);
  }

  void updateQty(int index, int qty) {
    if (qty <= 0) {
      removeAt(index);
      return;
    }
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) CartItem(product: state[i].product, quantity: qty) else state[i],
    ];
  }

  void clear() => state = [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final repositoryProvider = Provider<RepositoryImpl>((ref) {
  final db = ref.watch(databaseProvider);
  return RepositoryImpl(db);
});

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => Session.userId != null;

  Future<String?> login(String username, String password) async {
    try {
      final repo = ref.read(repositoryProvider);
      final ok = await repo.login(username, password);
      if (ok) {
        state = true;
        return null;
      }
      return 'Username atau password salah';
    } catch (e) {
      return 'Error: $e';
    }
  }

  void logout() {
    ref.read(repositoryProvider).logout();
    state = false;
  }
}

final currentUserProvider = FutureProvider<UserData?>((ref) async {
  final isLoggedIn = ref.watch(authProvider);
  if (!isLoggedIn) return null;
  final repo = ref.read(repositoryProvider);
  if (repo.currentUser == null) {
    await repo.restoreSession();
  }
  return repo.currentUser;
});

final productListProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(repositoryProvider).getAllProducts();
});

final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(repositoryProvider).getAllCategories();
});

final transactionListProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.read(repositoryProvider).getAllTransactions();
});

final lowStockProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(repositoryProvider).getLowStockProducts();
});

final taxPercentProvider = NotifierProvider<TaxPercentNotifier, double>(TaxPercentNotifier.new);

class TaxPercentNotifier extends Notifier<double> {
  @override
  double build() {
    _loadFromDb();
    return 11;
  }

  Future<void> _loadFromDb() async {
    try {
      final repo = ref.read(repositoryProvider);
      final val = await repo.getTaxPercent();
      state = val;
    } catch (_) {}
  }

  Future<void> update(double value) async {
    state = value;
    try {
      final repo = ref.read(repositoryProvider);
      await repo.setTaxPercent(value);
    } catch (_) {}
  }
}
