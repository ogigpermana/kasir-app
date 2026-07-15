import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_app/domain/entities/product.dart';
import 'package:kasir_app/domain/entities/transaction.dart';
import 'package:kasir_app/domain/entities/category.dart';

void main() {
  group('Product entity', () {
    test('copyWith updates fields correctly', () {
      final p = Product(
        name: 'Test',
        purchasePrice: 1000,
        sellingPrice: 2000,
        stock: 10,
        minStock: 2,
      );
      final updated = p.copyWith(name: 'Updated', stock: 5);
      expect(updated.name, 'Updated');
      expect(updated.stock, 5);
      expect(updated.sellingPrice, 2000);
      expect(updated.purchasePrice, 1000);
    });

    test('copyWith preserves null id', () {
      final p = Product(
        name: 'Test',
        purchasePrice: 1000,
        sellingPrice: 2000,
      );
      expect(p.id, isNull);
      final updated = p.copyWith(id: 1);
      expect(updated.id, 1);
    });
  });

  group('Transaction entity', () {
    test('calculates values correctly', () {
      final t = Transaction(
        invoiceNumber: 'INV-001',
        date: DateTime.now(),
        items: [],
        subtotal: 10000,
        tax: 1100,
        total: 11100,
        paid: 20000,
        change: 8900,
      );
      expect(t.subtotal, 10000);
      expect(t.tax, 1100);
      expect(t.total, 11100);
      expect(t.change, 8900);
    });

    test('copyWith retains other fields', () {
      final t = Transaction(
        invoiceNumber: 'INV-001',
        date: DateTime.now(),
        items: [],
        subtotal: 10000,
        tax: 1100,
        total: 11100,
        paid: 20000,
        change: 8900,
      );
      final updated = t.copyWith(total: 12000, paid: 12000, change: 0);
      expect(updated.total, 12000);
      expect(updated.paid, 12000);
      expect(updated.change, 0);
      expect(updated.invoiceNumber, 'INV-001');
      expect(updated.subtotal, 10000);
    });
  });

  group('Category entity', () {
    test('creates with default values', () {
      final c = Category(name: 'Minuman');
      expect(c.name, 'Minuman');
      expect(c.id, isNull);
      expect(c.description, isNull);
    });

    test('copyWith works correctly', () {
      final c = Category(id: 1, name: 'Makanan');
      final updated = c.copyWith(name: 'Snack');
      expect(updated.id, 1);
      expect(updated.name, 'Snack');
    });
  });
}
