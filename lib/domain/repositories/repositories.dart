import '../entities/product.dart';
import '../entities/category.dart';
import '../entities/transaction.dart';

abstract class ProductRepository {
  Future<List<Product>> getAllProducts();
  Future<Product?> getProductById(int id);
  Future<Product?> getProductByBarcode(String barcode);
  Future<Product> insertProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<void> updateStock(int productId, int quantity);

  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(int id);
  Future<Category> insertCategory(Category category);
  Future<Category> updateCategory(Category category);
  Future<void> deleteCategory(int id);
}

abstract class TransactionRepository {
  Future<List<Transaction>> getAllTransactions();
  Future<Transaction?> getTransactionById(int id);
  Future<Transaction> createTransaction(Transaction transaction);
  Future<List<Transaction>> getTransactionsByDate(DateTime date);
}
