import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _storeCtrl = TextEditingController();
  final _pageController = PageController();
  String _businessType = 'Toko Kelontong';

  final _businessTypes = [
    'Toko Kelontong',
    'Restoran / Cafe',
    'Fashion / Pakaian',
    'Elektronik',
    'Frozen Food',
    'Minimarket',
    'Toko Sembako',
    'Lainnya',
  ];

  @override
  void dispose() {
    _storeCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (_) => setState(() {}),
        children: [
          _buildWelcome(),
          _buildStoreForm(),
          _buildBusinessType(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.store, size: 96, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Text('Selamat Datang!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Atur toko Anda sebelum mulai menggunakan Kasir App.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const Spacer(),
          FilledButton(
            onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            child: const Text('Mulai Setup'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildStoreForm() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.storefront, size: 64, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Text('Nama Toko', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Masukkan nama toko atau usaha Anda.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _storeCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Toko',
                hintText: 'Misal: Toko Berkah Jaya',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Masukkan nama toko' : null,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            },
            child: const Text('Lanjut'),
          ),
          TextButton(
            onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            child: const Text('Kembali'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildBusinessType() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.category, size: 64, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Text('Jenis Usaha', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Pilih jenis usaha Anda.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: _businessTypes.map((type) => RadioListTile<String>(
                title: Text(type),
                value: type,
                groupValue: _businessType,
                onChanged: (v) => setState(() => _businessType = v!),
              )).toList(),
            ),
          ),
          FilledButton(
            onPressed: _save,
            child: const Text('Simpan & Mulai'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _save() async {
    if (_storeCtrl.text.trim().isEmpty) return;
    try {
      final repo = ref.read(repositoryProvider);
      await repo.completeOnboarding(_storeCtrl.text.trim(), _businessType);
      if (mounted) context.go('/pos');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
