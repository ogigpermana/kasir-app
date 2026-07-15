import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_app/domain/entities/category.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';

void _snack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: isError ? Colors.red : Colors.green,
  ));
}

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  final Set<int> _expandedParents = {};

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null, null),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada kategori', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }
          final parents = categories.where((c) => c.parentId == null).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(categoryListProvider),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: parents.map((parent) => _buildParentTile(context, ref, parent, categories)).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParentTile(BuildContext context, WidgetRef ref, Category parent, List<Category> all) {
    final children = all.where((c) => c.parentId == parent.id).toList();
    final isExpanded = _expandedParents.contains(parent.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: children.isNotEmpty ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
              child: Icon(children.isNotEmpty ? Icons.folder : Icons.category,
                  color: children.isNotEmpty ? Colors.orange : Colors.blue),
            ),
            title: Text(parent.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: parent.description != null ? Text(parent.description!) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (children.isNotEmpty)
                  IconButton(
                    icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() {
                      if (isExpanded) {
                        _expandedParents.remove(parent.id);
                      } else {
                        _expandedParents.add(parent.id!);
                      }
                    }),
                  ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'add_child') _addChild(context, ref, parent);
                    if (v == 'edit') _editCategory(context, ref, parent, null);
                    if (v == 'delete') _deleteCategory(context, ref, parent);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'add_child', child: ListTile(leading: Icon(Icons.add), title: Text('Tambah Sub'))),
                    const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Hapus', style: TextStyle(color: Colors.red)))),
                  ],
                ),
              ],
            ),
            onTap: children.isNotEmpty
                ? () => setState(() {
                      if (isExpanded) {
                        _expandedParents.remove(parent.id);
                      } else {
                        _expandedParents.add(parent.id!);
                      }
                    })
                : null,
          ),
          if (children.isNotEmpty && isExpanded)
            ...children.map((child) => ListTile(
              contentPadding: const EdgeInsets.only(left: 56, right: 16),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                child: const Icon(Icons.category, size: 16, color: Colors.grey),
              ),
              title: Text(child.name, style: const TextStyle(fontSize: 14)),
              subtitle: child.description != null ? Text(child.description!, style: const TextStyle(fontSize: 12)) : null,
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') _editCategory(context, ref, parent, child);
                  if (v == 'delete') {
                    try {
                      await ref.read(repositoryProvider).deleteCategory(child.id!);
                      ref.invalidate(categoryListProvider);
                      _snack(context, 'Sub kategori dihapus');
                    } catch (e) {
                      _snack(context, 'Gagal menghapus: $e', isError: true);
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                ],
              ),
            )),
        ],
      ),
    );
  }

  void _addChild(BuildContext context, WidgetRef ref, Category parent) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sub Kategori - ${parent.name}'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            try {
              await ref.read(repositoryProvider).insertCategory(Category(name: nameCtrl.text, parentId: parent.id));
              ref.invalidate(categoryListProvider);
              if (ctx.mounted) { Navigator.pop(ctx); _snack(context, 'Sub kategori ditambah'); }
            } catch (e) {
              if (ctx.mounted) _snack(context, 'Gagal: $e', isError: true);
            }
          }, child: const Text('Tambah')),
        ],
      ),
    );
  }

  void _editCategory(BuildContext context, WidgetRef ref, Category parent, Category? child) {
    final target = child ?? parent;
    final nameCtrl = TextEditingController(text: target.name);
    final descCtrl = TextEditingController(text: target.description ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            try {
              await ref.read(repositoryProvider).updateCategory(Category(
                id: target.id, name: nameCtrl.text,
                description: descCtrl.text.isEmpty ? null : descCtrl.text,
                parentId: target.parentId,
              ));
              ref.invalidate(categoryListProvider);
              if (ctx.mounted) { Navigator.pop(ctx); _snack(context, 'Kategori diupdate'); }
            } catch (e) {
              if (ctx.mounted) _snack(context, 'Gagal: $e', isError: true);
            }
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context, WidgetRef ref, Category category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            style: FilledButton.styleFrom(backgroundColor: Colors.red)),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(repositoryProvider).deleteCategory(category.id!);
        ref.invalidate(categoryListProvider);
        _snack(context, 'Kategori dihapus');
      } catch (e) {
        _snack(context, 'Gagal menghapus: $e', isError: true);
      }
    }
  }

  void _showForm(BuildContext context, WidgetRef ref, Category? category, int? parentId) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category != null ? 'Edit Kategori' : 'Tambah Kategori Utama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            try {
              if (category != null) {
                await ref.read(repositoryProvider).updateCategory(Category(id: category.id, name: nameCtrl.text, description: descCtrl.text.isEmpty ? null : descCtrl.text));
              } else {
                await ref.read(repositoryProvider).insertCategory(Category(name: nameCtrl.text, description: descCtrl.text.isEmpty ? null : descCtrl.text));
              }
              ref.invalidate(categoryListProvider);
              if (ctx.mounted) { Navigator.pop(ctx); _snack(context, category != null ? 'Kategori diupdate' : 'Kategori ditambah'); }
            } catch (e) {
              if (ctx.mounted) _snack(context, 'Gagal: $e', isError: true);
            }
          }, child: Text(category != null ? 'Simpan' : 'Tambah')),
        ],
      ),
    );
  }
}
