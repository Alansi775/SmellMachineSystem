import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../providers/ble_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BleProvider>(
      builder: (context, bleProvider, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Kontrol Merkezi'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Navigation buttons for steps
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed('/connection'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                    ),
                    child: const Text(
                      'Adim 1: Baglan',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed('/smells'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                    ),
                    child: const Text(
                      'Adim 2: Kokular',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed('/schedules'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                    ),
                    child: const Text(
                      'Adim 3: Takvim',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cihaz Durumu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bleProvider.isConnected
                        ? 'Difuzore bagli ve kullanim icin hazir.'
                        : 'Bagli degil. Baglanti ekrani uzerinden eslestirin.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bleProvider.isConnected
                          ? const Color(0xFF10B981).withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      bleProvider.isConnected ? 'BLE Bagli' : 'BLE Bekleniyor',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('Dil'),
                    subtitle: const Text('Turkce'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.check_circle_outline),
                                  title: const Text('Turkce'),
                                  onTap: () async {
                                    await context.read<LocaleProvider>().setLocale('tr');
                                    if (context.mounted) Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.language),
                                  title: const Text('English'),
                                  onTap: () async {
                                    await context.read<LocaleProvider>().setLocale('en');
                                    if (context.mounted) Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('Tum Verileri Sil'),
                    subtitle: const Text('Cihazdaki tum koku ve takvimleri temizle'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kullanim Icin Hazir',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu kurulum otel lobileri, suit odalar ve premium ticari alanlar icin uygundur.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
