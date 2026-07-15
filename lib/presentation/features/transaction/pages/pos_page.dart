import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/domain/entities/product.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';
import 'package:kasir_app/core/theme.dart';
import 'package:kasir_app/core/format_utils.dart';

class PosPage extends ConsumerWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Kasir'),
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => ref.read(cartProvider.notifier).clear(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) => _ProductGrid(
                products: products,
                onTap: (p) => ref.read(cartProvider.notifier).add(p),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 2,
            child: _CartPanel(cart: cart),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onTap;
  const _ProductGrid({required this.products, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('Belum ada produk'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
          child: InkWell(
            onTap: () => onTap(p),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(p.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Rp ${formatRupiah(p.sellingPrice)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text('Stok: ${p.stock}',
                      style: TextStyle(fontSize: 10, color: p.stock < 5 ? Colors.red : Colors.grey)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartPanel extends ConsumerStatefulWidget {
  final List<CartItem> cart;
  const _CartPanel({required this.cart});

  @override
  ConsumerState<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<_CartPanel> {
  bool _usePpn = true;

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.cart.fold<double>(0, (s, c) => s + c.product.sellingPrice * c.quantity);
    final taxPercent = ref.watch(taxPercentProvider);
    final tax = _usePpn ? subtotal * (taxPercent / 100) : 0.0;
    final total = subtotal + tax;

    return Column(
      children: [
        if (widget.cart.isEmpty)
          const Expanded(
            child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Tap produk untuk menambah ke keranjang',
                    style: TextStyle(color: Colors.grey)),
              ],
            )),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                final c = widget.cart[index];
                return ListTile(
                  dense: true,
                  title: Text(c.product.name),
                  subtitle: Text('Rp ${formatRupiah(c.product.sellingPrice)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () => ref.read(cartProvider.notifier).updateQty(index, c.quantity - 1),
                      ),
                      Text('${c.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () => ref.read(cartProvider.notifier).updateQty(index, c.quantity + 1),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text('Rp ${formatRupiah(c.product.sellingPrice * c.quantity)}',
                            textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (widget.cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('PPN', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Switch(
                      value: _usePpn,
                      onChanged: (v) => setState(() => _usePpn = v),
                    ),
                  ],
                ),
                _Row(label: 'Subtotal', value: subtotal),
                if (_usePpn) _Row(label: 'PPN ${taxPercent}%', value: tax),
                _Row(label: 'Total', value: total, bold: true),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: widget.cart.isEmpty ? null : () => context.go('/payment', extra: {
                    'total': total,
                    'subtotal': subtotal,
                    'tax': tax,
                  }),
                  icon: const Icon(Icons.payment),
                  label: const Text('Bayar'),
                  style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _Row({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            'Rp ${formatRupiah(value)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14),
          ),
        ],
      ),
    );
  }
}
