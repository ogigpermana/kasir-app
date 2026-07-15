import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';
import 'package:kasir_app/domain/entities/transaction.dart';
import 'package:kasir_app/core/format_utils.dart';
import 'package:kasir_app/core/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> _openFile(String path) async {
  try {
    await OpenFile.open(path);
  } catch (_) {}
}

final _dateRangeProvider = NotifierProvider<_DateRangeNotifier, DateTimeRange?>(_DateRangeNotifier.new);
final _periodProvider = NotifierProvider<_PeriodNotifier, String>(_PeriodNotifier.new);

class _DateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void update(DateTimeRange? v) => state = v;
}

class _PeriodNotifier extends Notifier<String> {
  @override
  String build() => 'Semua';
  void update(String v) => state = v;
}

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final selectedPeriod = ref.watch(_periodProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedPeriod),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter Tanggal',
            onPressed: () => _showPeriodPicker(context, ref),
          ),
          if (selectedPeriod != 'Semua')
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Hapus Filter',
              onPressed: () {
                ref.read(_periodProvider.notifier).update('Semua');
                ref.read(_dateRangeProvider.notifier).update(null);
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            ],
            onSelected: (v) async {
              final transactions = await _getFiltered(ref);
              if (v == 'csv') _exportCsv(context, ref, transactions);
              if (v == 'pdf') _exportPdf(context, ref, transactions);
            },
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final filtered = _filter(all, ref);
          final totalPenjualan = filtered.fold<double>(0, (s, t) => s + t.total);
          final totalTransaksi = filtered.length;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(transactionListProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Total Penjualan',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Rp ${formatRupiah(totalPenjualan)}',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(label: 'Transaksi', value: '$totalTransaksi'),
                            _StatItem(label: 'Rata-rata', value: 'Rp ${totalTransaksi > 0 ? formatRupiah(totalPenjualan / totalTransaksi) : '0'}'),
                          ],
                        ),
                        if (selectedPeriod != 'Semua') ...[
                          const SizedBox(height: 8),
                          Text('Periode: $selectedPeriod',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Riwayat Transaksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Tidak ada transaksi', style: TextStyle(color: Colors.grey)),
                  ))
                else
                  ...filtered.reversed.map((t) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(t.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(DateFormat('dd MMM yyyy HH:mm').format(t.date)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Rp ${formatRupiah(t.total)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${t.items.length} item',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Transaction> _filter(List<Transaction> all, WidgetRef ref) {
    final period = ref.read(_periodProvider);
    final range = ref.read(_dateRangeProvider);
    if (range != null) {
      return all.where((t) => t.date.isAfter(range.start.subtract(const Duration(days: 1))) && t.date.isBefore(range.end.add(const Duration(days: 1)))).toList();
    }
    if (period == 'Semua') return all;
    final now = DateTime.now();
    DateTime start;
    switch (period) {
      case 'Hari Ini':
        start = DateTime(now.year, now.month, now.day);
        return all.where((t) => t.date.isAfter(start)).toList();
      case 'Minggu Ini':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        return all.where((t) => t.date.isAfter(start)).toList();
      case 'Bulan Ini':
        start = DateTime(now.year, now.month, 1);
        return all.where((t) => t.date.isAfter(start)).toList();
      case 'Tahun Ini':
        start = DateTime(now.year, 1, 1);
        return all.where((t) => t.date.isAfter(start)).toList();
      default:
        return all;
    }
  }
}

void _showPeriodPicker(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Filter Laporan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('Semua Waktu'), onTap: () {
            ref.read(_periodProvider.notifier).update('Semua');
            ref.read(_dateRangeProvider.notifier).update(null);
            Navigator.pop(ctx);
          }),
          ListTile(title: const Text('Hari Ini'), onTap: () {
            ref.read(_periodProvider.notifier).update('Hari Ini');
            ref.read(_dateRangeProvider.notifier).update(null);
            Navigator.pop(ctx);
          }),
          ListTile(title: const Text('Minggu Ini'), onTap: () {
            ref.read(_periodProvider.notifier).update('Minggu Ini');
            Navigator.pop(ctx);
          }),
          ListTile(title: const Text('Bulan Ini'), onTap: () {
            ref.read(_periodProvider.notifier).update('Bulan Ini');
            Navigator.pop(ctx);
          }),
          ListTile(title: const Text('Tahun Ini'), onTap: () {
            ref.read(_periodProvider.notifier).update('Tahun Ini');
            Navigator.pop(ctx);
          }),
          ListTile(
            title: const Text('Pilih Tanggal...'),
            leading: const Icon(Icons.calendar_month),
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (range != null) {
                ref.read(_dateRangeProvider.notifier).update(range);
                ref.read(_periodProvider.notifier).update('${DateFormat('dd/MM').format(range.start)} - ${DateFormat('dd/MM/yyyy').format(range.end)}');
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );
}

Future<List<Transaction>> _getFiltered(WidgetRef ref) async {
  final all = await ref.read(repositoryProvider).getAllTransactions();
  final range = ref.read(_dateRangeProvider);
  if (range != null) {
    return all.where((t) => t.date.isAfter(range.start.subtract(const Duration(days: 1))) && t.date.isBefore(range.end.add(const Duration(days: 1)))).toList();
  }
  final period = ref.read(_periodProvider);
  if (period == 'Semua') return all;
  final now = DateTime.now();
  DateTime start;
  switch (period) {
    case 'Hari Ini': start = DateTime(now.year, now.month, now.day); break;
    case 'Minggu Ini': start = DateTime(now.year, now.month, now.day - now.weekday + 1); break;
    case 'Bulan Ini': start = DateTime(now.year, now.month, 1); break;
    case 'Tahun Ini': start = DateTime(now.year, 1, 1); break;
    default: return all;
  }
  return all.where((t) => t.date.isAfter(start)).toList();
}

Future<void> _exportCsv(BuildContext context, WidgetRef ref, List<Transaction> transactions) async {
  try {
    final repo = ref.read(repositoryProvider);
    final storeName = await repo.getStoreName();
    final businessType = await repo.getBusinessType();
    final buffer = StringBuffer();
    buffer.writeln('Nama Toko,$storeName');
    if (businessType.isNotEmpty) buffer.writeln('Jenis Usaha,$businessType');
    buffer.writeln('Invoice,Tanggal,Item,Subtotal,Pajak,Total,Dibayar,Kembalian');
    for (final t in transactions) {
      buffer.writeln('${t.invoiceNumber},${t.date.toIso8601String()},${t.items.length},${t.subtotal},${t.tax},${t.total},${t.paid},${t.change}');
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = await FileSaver.saveToDocuments(
      fileName: 'laporan_kasir_$timestamp.csv',
      bytes: utf8.encode(buffer.toString()),
      mimeType: 'text/csv',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV tersimpan di:\n$path'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Buka', textColor: Colors.white, onPressed: () => _openFile(path)),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export CSV: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

Future<void> _exportPdf(BuildContext context, WidgetRef ref, List<Transaction> transactions) async {
  try {
    final repo = ref.read(repositoryProvider);
    final storeName = await repo.getStoreName();
    final businessType = await repo.getBusinessType();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          final totalAll = transactions.fold<double>(0, (s, t) => s + t.total);
          return [
            pw.Header(level: 0, text: storeName),
            if (businessType.isNotEmpty)
              pw.Paragraph(text: businessType, style: pw.TextStyle(color: PdfColors.grey)),
            pw.SizedBox(height: 8),
            pw.Paragraph(text: 'Laporan Penjualan'),
            pw.SizedBox(height: 8),
            pw.Paragraph(text: 'Total Transaksi: ${transactions.length}'),
            pw.Paragraph(text: 'Total Penjualan: Rp ${formatRupiah(totalAll)}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Invoice', 'Tanggal', 'Item', 'Total', 'Dibayar'],
              data: transactions.reversed.map<List<String>>((t) => [
                t.invoiceNumber,
                DateFormat('dd/MM/yyyy HH:mm').format(t.date),
                '${t.items.length}',
                'Rp ${formatRupiah(t.total)}',
                'Rp ${formatRupiah(t.paid)}',
              ]).toList(),
            ),
          ];
        },
      ),
    );
    final bytes = await pdf.save();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = await FileSaver.saveToDocuments(
      fileName: 'laporan_kasir_$timestamp.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF tersimpan di:\n$path'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Buka', textColor: Colors.white, onPressed: () => _openFile(path)),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
