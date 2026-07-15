import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_app/domain/entities/product.dart';
import 'package:kasir_app/domain/entities/category.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';
import 'package:kasir_app/core/theme.dart';
import 'package:kasir_app/core/format_utils.dart';

class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Kelola Kategori',
            onPressed: () => GoRouter.of(context).go('/categories'),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) => _ProductList(
          products: products,
          categories: categoriesAsync.asData?.value ?? [],
          ref: ref,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context, ref, null, categoriesAsync.asData?.value ?? []),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;
  final List<Category> categories;
  final WidgetRef ref;
  const _ProductList({required this.products, required this.categories, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada produk', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(productListProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          final catName = _getCategoryName(p.categoryId, categories);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppTheme.primary)),
              ),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${catName.isNotEmpty ? '$catName • ' : ''}Rp ${formatRupiah(p.sellingPrice)}  |  Stok: ${p.stock}',
                style: TextStyle(color: p.stock < 5 ? Colors.red : Colors.grey[600]),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') _showProductForm(context, ref, p, categories);
                  if (v == 'delete') await _delete(context, ref, p);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Hapus', style: TextStyle(color: Colors.red)))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryName(int? categoryId, List<Category> cats) {
    final c = cats.where((c) => c.id == categoryId).firstOrNull;
    if (c == null) return '';
    if (c.parentId != null) {
      final parent = cats.where((p) => p.id == c.parentId).firstOrNull;
      return parent != null ? '${parent.name} > ${c.name}' : c.name;
    }
    return c.name;
  }
}

Future<void> _delete(BuildContext context, WidgetRef ref, Product p) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus Produk'),
      content: Text('Yakin ingin menghapus "${p.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          style: FilledButton.styleFrom(backgroundColor: Colors.red)),
      ],
    ),
  );
  if (ok == true) {
    try {
      await ref.read(repositoryProvider).deleteProduct(p.id!);
      ref.invalidate(productListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${p.name}" berhasil dihapus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

void _showProductForm(BuildContext context, WidgetRef ref, Product? product, List<Category> categories) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ProductForm(product: product, categories: categories, ref: ref),
  );
}

class _ProductForm extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final WidgetRef ref;
  const _ProductForm({this.product, required this.categories, required this.ref});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _purchaseCtrl;
  late final TextEditingController _sellingCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  int? _selectedParentId;
  int? _selectedChildId;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.product != null;
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _barcodeCtrl = TextEditingController(text: widget.product?.barcode ?? '');
    _purchaseCtrl = TextEditingController(text: widget.product?.purchasePrice.toString() ?? '');
    _sellingCtrl = TextEditingController(text: widget.product?.sellingPrice.toString() ?? '');
    _stockCtrl = TextEditingController(text: widget.product?.stock.toString() ?? '0');
    _minStockCtrl = TextEditingController(text: widget.product?.minStock.toString() ?? '0');

    if (isEdit && widget.product?.categoryId != null) {
      final cat = widget.categories.where((c) => c.id == widget.product!.categoryId).firstOrNull;
      if (cat != null) {
        if (cat.parentId == null) {
          // produk dikategorikan ke parent (tanpa sub)
          _selectedParentId = cat.id;
          _selectedChildId = null;
        } else {
          // produk dikategorikan ke sub kategori
          _selectedParentId = cat.parentId;
          _selectedChildId = cat.id;
        }
      }
    }

    if (!isEdit && _barcodeCtrl.text.isEmpty) {
      _barcodeCtrl.text = widget.ref.read(repositoryProvider).generateBarcode();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchaseCtrl.dispose();
    _sellingCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final repo = widget.ref.read(repositoryProvider);
    final tree = repo.buildCategoryTree(widget.categories);
    final parents = tree;

    final parentItems = <DropdownMenuItem<int>>[
      const DropdownMenuItem(value: null, child: Text('Pilih kategori utama')),
      ...parents.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
    ];

    final selectedParent = parents.where((p) => p.id == _selectedParentId).firstOrNull;
    final children = selectedParent?.children ?? [];
    final hasChildren = children.isNotEmpty;
    final chipOptions = hasChildren ? children : (selectedParent != null ? [selectedParent] : []);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Edit Produk' : 'Tambah Produk',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedParentId,
                decoration: const InputDecoration(labelText: 'Kategori Utama'),
                items: parentItems,
                onChanged: (v) => setState(() {
                  _selectedParentId = v;
                  _selectedChildId = null;
                  final p = parents.where((x) => x.id == v).firstOrNull;
                  final kids = p?.children ?? [];
                  if (v != null && kids.isEmpty && p != null) {
                    _selectedChildId = p.id;
                    _nameCtrl.text = p.name;
                  } else {
                    _nameCtrl.clear();
                  }
                }),
              ),
              if (_selectedParentId != null && chipOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(hasChildren ? 'Pilih Sub Kategori' : 'Nama dari Kategori',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: chipOptions.map((c) {
                    final selected = c.id == _selectedChildId;
                    return ChoiceChip(
                      label: Text(c.name),
                      selected: selected,
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedChildId = c.id;
                            _nameCtrl.text = c.name;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Produk',
                  hintText: hasChildren && _selectedChildId == null
                      ? 'Pilih sub kategori di atas'
                      : null,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      decoration: const InputDecoration(labelText: 'Barcode', suffixIcon: Icon(Icons.qr_code)),
                    ),
                  ),
                  if (!isEdit)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => setState(() {
                        _barcodeCtrl.text = widget.ref.read(repositoryProvider).generateBarcode();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchaseCtrl,
                      decoration: const InputDecoration(labelText: 'Harga Beli'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingCtrl,
                      decoration: const InputDecoration(labelText: 'Harga Jual'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockCtrl,
                      decoration: const InputDecoration(labelText: 'Min. Stok'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: Text(isEdit ? 'Simpan' : 'Tambah'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final repo = widget.ref.read(repositoryProvider);
      final product = Product(
        id: widget.product?.id,
        categoryId: _selectedChildId ?? _selectedParentId,
        name: _nameCtrl.text,
        barcode: _barcodeCtrl.text.isEmpty ? null : _barcodeCtrl.text,
        purchasePrice: double.tryParse(_purchaseCtrl.text) ?? 0,
        sellingPrice: double.tryParse(_sellingCtrl.text) ?? 0,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        minStock: int.tryParse(_minStockCtrl.text) ?? 0,
      );
      if (widget.product != null) {
        await repo.updateProduct(product);
      } else {
        await repo.insertProduct(product);
      }
      widget.ref.invalidate(productListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.product != null ? 'Produk berhasil diupdate' : 'Produk berhasil ditambah'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
