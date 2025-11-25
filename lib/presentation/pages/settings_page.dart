import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<bool>(
        valueListenable: themeNotifier,
        builder: (context, isDarkMode, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: isDarkMode,
                onChanged: (_) => themeNotifier.toggleTheme(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () => _signOut(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
