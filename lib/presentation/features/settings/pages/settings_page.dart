import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/core/constants.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    final isKasir = user?.role == 'kasir';

    if (isKasir) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 32,
                    child: Text(user?.displayName[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(height: 8),
                  Text(user?.displayName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('@${user?.username ?? ''}  |  ${user?.role ?? ''}', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: CircleAvatar(child: Text(user?.displayName[0].toUpperCase() ?? '?')),
                    title: Text(user?.displayName ?? ''),
                    subtitle: Text('@${user?.username ?? ''}  |  ${user?.role ?? ''}'),
                  ),
                  if (user?.role == 'admin' || user?.role == 'owner') ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Manajemen User'),
                      subtitle: const Text('Tambah, edit, hapus user'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/users'),
                    ),
                  ],
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.percent),
                    title: const Text('Pengaturan Pajak'),
                    subtitle: Text('PPN: ${ref.watch(taxPercentProvider)}%'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showTaxDialog(context, ref),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Kasir App v${AppConstants.version}',
                style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  void _showTaxDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: ref.read(taxPercentProvider).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PPN (Pajak)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Persentase PPN', suffixText: '%'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            final val = double.tryParse(ctrl.text) ?? 11;
            await ref.read(taxPercentProvider.notifier).update(val);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
