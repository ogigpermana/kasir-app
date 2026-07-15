import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_app/presentation/common/providers/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.store, size: 72, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                const Text('Kasir App', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Silakan login untuk melanjutkan',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.isEmpty ? 'Masukkan username' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  validator: (v) => v == null || v.isEmpty ? 'Masukkan password' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: (_loading) ? null : _login,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Default: admin / admin123', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final error = await ref.read(authProvider.notifier).login(
        _usernameCtrl.text,
        _passwordCtrl.text,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() { _loading = false; _error = error; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Terjadi error: $e'; });
    }
  }
}
