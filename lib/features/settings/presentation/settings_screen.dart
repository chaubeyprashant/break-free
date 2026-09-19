import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/features/auth/presentation/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('Break Free Hero'),
            accountEmail: Text('Level 5'),
            currentAccountPicture: CircleAvatar(child: Text('🦸')),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Daily Check-ins: 8:00 PM'),
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('App Blocker'),
            subtitle: const Text('Restrict distracting apps'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/app-blocker');
            },
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner),
            title: const Text('Transaction Scanner'),
            subtitle: const Text('Detect smoking-related purchases'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/scanner-settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt),
            title: const Text('Accountability Partner'),
            subtitle: const Text('Auto-notify a friend if you slip up'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/accountability-settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            subtitle: const Text('Break Free Teal'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy & Data'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset All Progress'),
            textColor: Colors.red,
            onTap: () {
              // TODO: Reset Logic
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out'),
            textColor: Colors.red,
            onTap: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            },
          ),
        ],
      ),
    );
  }
}
