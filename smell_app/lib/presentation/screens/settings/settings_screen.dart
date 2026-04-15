/// Settings screen for app preferences and device management.
///
/// Provides options for:
/// - Switching language (English/Turkish)
/// - Wiping all device data
/// - Viewing app version/info
///
/// TODO: Implement language switching
/// TODO: Implement data wipe confirmation dialog
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // TODO: Language selector
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('English'),
            onTap: () {
              // TODO: Show language picker
            },
          ),
          const Divider(),
          // TODO: Wipe data button
          ListTile(
            title: const Text('Wipe All Data'),
            subtitle: const Text('Remove all smells and schedules from device'),
            onTap: () {
              // TODO: Show confirmation dialog
            },
          ),
        ],
      ),
    );
  }
}
