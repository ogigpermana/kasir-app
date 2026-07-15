import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_app/domain/entities/transaction.dart';
import 'package:kasir_app/core/format_utils.dart';

class ReceiptDialog extends StatelessWidget {
  final Transaction transaction;
  final String storeName;

  const ReceiptDialog({super.key, required this.transaction, this.storeName = 'Kasir App'});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(),
                Text('No: ${transaction.invoiceNumber}'),
                Text(DateFormat('dd MMM yyyy HH:mm').format(transaction.date)),
                const Divider(),
                ...transaction.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.productName)),
                      Text('${item.quantity}x '),
                      Text('Rp ${formatRupiah(item.subtotal)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
                const Divider(),
                _line('Subtotal', transaction.subtotal),
                _line('Pajak', transaction.tax),
                _line('Total', transaction.total, bold: true),
                const Divider(),
                _line('Tunai', transaction.paid),
                _line('Kembali', transaction.change),
                const SizedBox(height: 16),
                Text('Terima Kasih', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('Rp ${formatRupiah(value)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}
