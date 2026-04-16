import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/device_config.dart';
import '../../../providers/smells_provider.dart';
import '../../../providers/schedules_provider.dart';
import '../../../providers/ble_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';
import '../../../core/utils/logger.dart';

class SmellsScreen extends StatefulWidget {
  const SmellsScreen({super.key});

  @override
  State<SmellsScreen> createState() => _SmellsScreenState();
}

class _SmellsScreenState extends State<SmellsScreen> {
  final _smellNameController = TextEditingController();
  String? _editingSmellId;

  @override
  void dispose() {
    _smellNameController.dispose();
    super.dispose();
  }

  void _startEditingSmell(String smellId, String smellName) {
    setState(() {
      _editingSmellId = smellId;
      _smellNameController.text = smellName;
    });
  }

  void _clearEditing() {
    setState(() {
      _editingSmellId = null;
      _smellNameController.clear();
    });
  }

  Future<void> _syncDeviceState() async {
    final bleProvider = context.read<BleProvider>();
    if (!bleProvider.isConnected) {
      return;
    }

    final smellsProvider = context.read<SmellsProvider>();
    final schedulesProvider = context.read<SchedulesProvider>();
    final config = DeviceConfig(
      smells: smellsProvider.smells,
      schedules: schedulesProvider.schedules,
    );

    final success = await bleProvider.syncDeviceConfig(config);
    if (success) {
      Logger.info('Full config synced after smell change');
    }
  }

  Future<void> _submitSmell(
    SmellsProvider smellsProvider,
    SchedulesProvider schedulesProvider,
  ) async {
    final smellName = _smellNameController.text.trim();
    if (smellName.isEmpty) {
      return;
    }

    final bleProvider = context.read<BleProvider>();
    if (_editingSmellId == null) {
      await smellsProvider.addSmell(smellName, bleProvider);
    } else {
      await smellsProvider.updateSmell(_editingSmellId!, smellName, bleProvider);
    }

    await _syncDeviceState();
    _clearEditing();
  }

  Future<void> _deleteSmell(
    String smellId,
    SmellsProvider smellsProvider,
    SchedulesProvider schedulesProvider,
  ) async {
    final bleProvider = context.read<BleProvider>();
    await smellsProvider.deleteSmell(smellId, bleProvider);
    schedulesProvider.removeSchedulesForSmell(smellId);
    if (_editingSmellId == smellId) {
      _clearEditing();
    }
    await _syncDeviceState();
  }

  Widget _buildSmellChip(BuildContext context, String label, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? const Color(0xFF0A0A0A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? Colors.white : const Color(0xFF0A0A0A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Kokular',
      body: Consumer2<SmellsProvider, SchedulesProvider>(
        builder: (context, smellsProvider, schedulesProvider, _) {
          final bleProvider = context.watch<BleProvider>();
          final isEditing = _editingSmellId != null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const SectionLabel(text: 'ADIM 2 / 3'),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF111827), Color(0xFF374151)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koku Kutuphanesi',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yeniden adlandirmak icin bir kokuya dokunun. Silmek, ilgili takvimleri de kaldirir.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSmellChip(context, '${smellsProvider.count} koku', true),
                          const SizedBox(width: 10),
                          _buildSmellChip(
                            context,
                            bleProvider.isConnected ? 'BLE bagli' : 'Cevrimdisi duzenleme',
                            bleProvider.isConnected,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Kokuyu yeniden adlandir' : 'Yeni koku ekle',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _smellNameController,
                          cursorColor: const Color(0xFF0A0A0A),
                          style: const TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Koku adi',
                            labelStyle: const TextStyle(
                              color: Color(0xFF6B7280),
                            ),
                            hintText: 'Gul, Okyanus, Lavanta...',
                            hintStyle: const TextStyle(
                              color: Color(0xFFD1D5DB),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A0A0A),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: isEditing ? 'Degisiklikleri kaydet' : 'Koku ekle',
                                leadingIcon: Icon(
                                  isEditing ? Icons.save_outlined : Icons.add,
                                ),
                                onPressed: () => _submitSmell(
                                  smellsProvider,
                                  schedulesProvider,
                                ),
                              ),
                            ),
                            if (isEditing) ...[
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: _clearEditing,
                                child: const Text('Iptal'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (smellsProvider.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_florist_rounded,
                          size: 60,
                          color: Color(0xFF0A0A0A),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bu cihazda henuz koku yok',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ilk kokuyu yukaridan ekleyin. Yerel kaydedilir ve BLE baglaninca ESP32 ye gonderilir.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else ...[
                  const SectionLabel(text: 'CIHAZDAKI KOKULAR'),
                  const SizedBox(height: 12),
                  ...smellsProvider.smells.map((smell) {
                    final selected = _editingSmellId == smell.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _startEditingSmell(smell.id, smell.name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFF4F4F5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF0A0A0A),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      smell.name,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: selected ? Colors.white : const Color(0xFF0A0A0A),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Duzenlemek veya yeniden adlandirmak icin dokunun',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: selected
                                            ? Colors.white.withValues(alpha: 0.7)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: selected ? Colors.white : const Color(0xFFEF4444),
                                onPressed: () => _deleteSmell(
                                  smell.id,
                                  smellsProvider,
                                  schedulesProvider,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Sonraki: Takvimler',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/schedules');
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
