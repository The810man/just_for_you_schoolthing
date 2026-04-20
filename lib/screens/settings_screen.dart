import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/modules_provider.dart';

// Legacy settings screen - now the admin panel handles module management.
// This screen is kept for compatibility but users are directed to AdminScreen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesState = ref.watch(modulesProvider);
    final notifier = ref.read(modulesProvider.notifier);
    final modules = modulesState.installed;

    return Scaffold(
      appBar: AppBar(title: const Text('Installierte Module'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Installierte Module (${modules.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: modules.isEmpty
                  ? Center(
                      child: Text(
                        'Keine Module installiert',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final module = modules[index];
                        final isActive =
                            modulesState.activeIds.contains(module.name);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: Icon(
                              Icons.apps,
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                            title: Text(module.name),
                            subtitle: Text(
                              '${module.description}${isActive ? ' · Aktiv' : ''}',
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () {
                                _showDeleteDialog(
                                  context,
                                  module.name,
                                  () {
                                    notifier.removeModule(module.name);
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String moduleName,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modul löschen'),
        content: Text('Modul "$moduleName" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: onConfirm,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
