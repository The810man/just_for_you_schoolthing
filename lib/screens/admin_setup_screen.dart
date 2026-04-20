import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AdminSetupScreen extends ConsumerStatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  ConsumerState<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends ConsumerState<AdminSetupScreen> {
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    if (_pwCtrl.text.length < 4) {
      setState(() => _error = 'Mindestens 4 Zeichen erforderlich');
      return;
    }
    if (_pwCtrl.text != _pw2Ctrl.text) {
      setState(() => _error = 'Passwörter stimmen nicht überein');
      return;
    }
    await ref.read(authProvider.notifier).setupPassword(_pwCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 64, color: Color(0xFF1565C0)),
                  const SizedBox(height: 16),
                  Text(
                    'JustForYou',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1565C0),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Admin-Ersteinrichtung',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _pwCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Admin-Passwort festlegen',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pw2Ctrl,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: 'Passwort wiederholen',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    onSubmitted: (_) => _setup(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _setup,
                      icon: const Icon(Icons.check),
                      label: const Text('Einrichtung abschließen'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
