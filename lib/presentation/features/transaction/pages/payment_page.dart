import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/domain/entities/transaction.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';
import 'package:kasir_app/core/format_utils.dart';
import 'package:kasir_app/core/theme.dart';
import 'receipt_dialog.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final double total;
  final double subtotal;
  final double tax;

  const PaymentPage({
    super.key,
    required this.total,
    required this.subtotal,
    required this.tax,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  late final TextEditingController _paidCtrl;
  double _change = 0;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _paidCtrl = TextEditingController(text: widget.total.toStringAsFixed(0));
    _paidCtrl.addListener(_calcChange);
    _calcChange();
  }

  void _calcChange() {
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    setState(() => _change = paid - widget.total);
  }

  @override
  void dispose() {
    _paidCtrl.dispose();
    super.dispose();
  }

  void _pay() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final cart = ref.read(cartProvider);
      final repo = ref.read(repositoryProvider);
      final paid = double.tryParse(_paidCtrl.text) ?? 0;
      final transaction = await repo.createTransaction(Transaction(
        invoiceNumber: '',
        date: DateTime.now(),
        items: cart.map((c) => TransactionItem(
          productId: c.product.id!,
          productName: c.product.name,
          price: c.product.sellingPrice,
          quantity: c.quantity,
          subtotal: c.product.sellingPrice * c.quantity,
        )).toList(),
        subtotal: widget.subtotal,
        tax: widget.tax,
        total: widget.total,
        paid: paid,
        change: paid - widget.total,
      ));
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(transactionListProvider);
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockProvider);
      if (mounted) {
        final storeName = await repo.getStoreName();
        if (mounted) {
          context.go('/pos');
          showDialog(context: context, builder: (_) => ReceiptDialog(transaction: transaction, storeName: storeName));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses transaksi: $e'), backgroundColor: Colors.red),
        );
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: AppTheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Total Belanja', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('Rp ${formatRupiah(widget.total)}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _paidCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Dibayar',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kembalian', style: TextStyle(fontSize: 16)),
                      Text('Rp ${formatRupiah(_change)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _change >= 0 ? Colors.green : Colors.red,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: (_change >= 0 && !_processing) ? _pay : null,
                icon: _processing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle),
                label: Text(_processing ? 'Memproses...' : 'Selesai'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _processing ? null : () => context.go('/pos'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
