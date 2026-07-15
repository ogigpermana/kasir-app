import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';
import 'package:kasir_app/core/theme.dart';

class StockPage extends ConsumerWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Stok')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada produk', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tambah produk dulu di menu Produk', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          final lowStock = products.where((p) => p.stock <= p.minStock).toList();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (lowStock.isNotEmpty) ...[
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('${lowStock.length} produk stok menipis!',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ...products.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.stock <= p.minStock ? Colors.red.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(p.name[0].toUpperCase(),
                        style: TextStyle(color: p.stock <= p.minStock ? Colors.red : AppTheme.primary)),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Min: ${p.minStock}  |  Stok: ${p.stock}'),
                  trailing: Text('${p.stock}', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: p.stock <= p.minStock ? Colors.red : Colors.green,
                  )),
                  onTap: () => _showAdjustDialog(context, ref, p.id!, p.name, p.stock),
                ),
              )),
            ],
          );
        },
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, WidgetRef ref, int productId, String name, int currentStock) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust Stok - $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stok saat ini: $currentStock'),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Jumlah (+/-)', prefixText: 'Stok: '),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            final qty = int.tryParse(ctrl.text) ?? 0;
            if (qty != 0) {
              try {
                await ref.read(repositoryProvider).adjustStock(productId, qty, 'adjustment');
                ref.invalidate(productListProvider);
                ref.invalidate(lowStockProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stok $name: ${qty > 0 ? "+" : ""}$qty'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            }
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
