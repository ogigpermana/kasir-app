import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';
import 'package:kasir_app/data/repositories/repository_impl.dart';

final userListProvider = FutureProvider<List<UserData>>((ref) async {
  return ref.read(repositoryProvider).getAllUsers();
});

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListProvider);
    final currentUser = ref.read(repositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen User')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(context, ref, null),
        child: const Icon(Icons.person_add),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('Belum ada user'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                final isSelf = currentUser != null && u.id == currentUser.id;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(u.displayName[0].toUpperCase())),
                    title: Text(u.displayName),
                    subtitle: Text('@${u.username}  |  ${u.role}${!u.isActive ? '  (nonaktif)' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(label: Text(u.role, style: const TextStyle(fontSize: 11))),
                        if (!isSelf)
                          PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') _showUserForm(context, ref, u);
                              if (v == 'toggle') {
                                await ref.read(repositoryProvider).updateUser(u.id, isActive: !u.isActive);
                                ref.invalidate(userListProvider);
                              }
                              if (v == 'delete') {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus User'),
                                    content: Text('Yakin ingin menghapus "${u.displayName}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                        style: FilledButton.styleFrom(backgroundColor: Colors.red)),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await ref.read(repositoryProvider).deleteUser(u.id);
                                  ref.invalidate(userListProvider);
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('User berhasil dihapus'), backgroundColor: Colors.green),
                                  );
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'toggle', child: Text(u.isActive ? 'Nonaktifkan' : 'Aktifkan')),
                              const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showUserForm(BuildContext context, WidgetRef ref, UserData? user) {
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final displayCtrl = TextEditingController(text: user?.displayName ?? '');
    final passCtrl = TextEditingController();
    String role = user?.role ?? 'kasir';
    final isEdit = user != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit User' : 'Tambah User'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                  enabled: !isEdit,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: displayCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                if (!isEdit)
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    obscureText: true,
                  ),
                if (!isEdit) const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                    DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  ],
                  onChanged: (v) => setState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              try {
                final repo = ref.read(repositoryProvider);
                if (isEdit) {
                  await repo.updateUser(user.id, displayName: displayCtrl.text, role: role);
                  if (passCtrl.text.isNotEmpty) {
                    await repo.updateUser(user.id, password: passCtrl.text);
                  }
                } else {
                  if (usernameCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                  await repo.createUser(usernameCtrl.text, passCtrl.text, displayCtrl.text, role);
                }
                ref.invalidate(userListProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'User berhasil diupdate' : 'User berhasil ditambah'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            }, child: Text(isEdit ? 'Simpan' : 'Tambah')),
          ],
        ),
      ),
    );
  }
}
