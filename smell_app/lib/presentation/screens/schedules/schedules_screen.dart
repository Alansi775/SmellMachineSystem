import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/device_config.dart';
import '../../../data/models/schedule.dart';
import '../../../data/models/smell.dart';
import '../../../providers/ble_provider.dart';
import '../../../providers/schedules_provider.dart';
import '../../../providers/smells_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/section_label.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSmellId;
  String? _editingScheduleId;
  final Set<int> _selectedDays = {0};
  final _startTimeController = TextEditingController(text: '08:00');
  final _endTimeController = TextEditingController(text: '18:00');

  static const List<String> _dayNames = [
    'Pazartesi',
    'Sali',
    'Carsamba',
    'Persembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  int _timeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  String _formatDay(int dayOfWeek) {
    return _dayNames[dayOfWeek.clamp(0, _dayNames.length - 1)];
  }

  void _resetForm() {
    setState(() {
      _editingScheduleId = null;
      _selectedDays
        ..clear()
        ..add(0);
      _startTimeController.text = '08:00';
      _endTimeController.text = '18:00';
    });
  }

  void _fillFormFromSchedule(Schedule schedule) {
    setState(() {
      _editingScheduleId = schedule.id;
      _selectedSmellId = schedule.smellId;
      _selectedDays
        ..clear()
        ..add(schedule.dayOfWeek);
      _startTimeController.text = schedule.startTime;
      _endTimeController.text = schedule.endTime;
    });
  }

  void _selectSmell(String? smellId) {
    setState(() {
      _selectedSmellId = smellId;
    });
  }

  Future<void> _syncDeviceConfig(
    BleProvider bleProvider,
    SchedulesProvider schedulesProvider,
    SmellsProvider smellsProvider,
  ) async {
    if (!bleProvider.isConnected) {
      return;
    }

    final success = await bleProvider.syncDeviceConfig(
      DeviceConfig(
        smells: smellsProvider.smells,
        schedules: schedulesProvider.schedules,
      ),
    );

    if (success) {
      Logger.info('Full config synced after schedule change');
    }
  }

  String? _getNextSmellName(
    SchedulesProvider schedulesProvider,
    SmellsProvider smellsProvider,
  ) {
    if (schedulesProvider.schedules.isEmpty || smellsProvider.smells.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final currentDay = (now.weekday + 6) % 7;
    final currentMinutes = now.hour * 60 + now.minute;

    int? bestDelta;
    String? bestSmellId;

    for (final schedule in schedulesProvider.schedules) {
      final start = _timeToMinutes(schedule.startTime);
      int delta = ((schedule.dayOfWeek - currentDay + 7) % 7) * 1440 +
          (start - currentMinutes);
      if (delta < 0) {
        delta += 7 * 1440;
      }

      if (bestDelta == null || delta < bestDelta) {
        bestDelta = delta;
        bestSmellId = schedule.smellId;
      }
    }

    if (bestSmellId == null) return null;
    final matches = smellsProvider.smells.where((smell) => smell.id == bestSmellId);
    return matches.isEmpty ? null : matches.first.name;
  }

  Future<void> _handleSubmit(
    SchedulesProvider schedulesProvider,
    SmellsProvider smellsProvider,
    BleProvider bleProvider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (smellsProvider.smells.isEmpty || schedulesProvider.schedules.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Gondermek icin en az bir koku ve bir takvim gerekli')),
      );
      return;
    }

    if (!bleProvider.isConnected) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bluetooth Baglantisi Yok'),
          content: const Text('Ayarlari gondermek icin once cihaza baglanin.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/connection');
              },
              child: const Text('Adim 1: Baglan'),
            ),
          ],
        ),
      );
      return;
    }

    final config = DeviceConfig(
      smells: smellsProvider.smells,
      schedules: schedulesProvider.schedules,
    );

    final payload = jsonEncode(config.toJson());
    Logger.info('Applying full config from Submit: $payload');
    final ok = await bleProvider.sendConfig(payload);

    if (!mounted) return;

    if (!ok) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Ayarlar cihaza gonderilemedi')),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 400));

    final nextSmell = bleProvider.lastNextSmellName ??
        _getNextSmellName(schedulesProvider, smellsProvider);
    final deviceMessage = bleProvider.lastDeviceMessage;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Ayarlar Uygulandi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  nextSmell == null
                      ? (deviceMessage ?? 'Ayarlariniz artik cihazda aktif.')
                      : 'Sonraki koku: $nextSmell',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitSchedule(
    SchedulesProvider schedulesProvider,
    SmellsProvider smellsProvider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (smellsProvider.smells.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Once en az bir koku ekleyin')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('En az bir gun secin')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bleProvider = context.read<BleProvider>();
    if (_editingScheduleId == null) {
      final targetSmellIds = _selectedSmellId == null
          ? smellsProvider.smells.map((smell) => smell.id).toList()
          : <String>[_selectedSmellId!];

      int addedCount = 0;
      for (final day in _selectedDays.toList()..sort()) {
        for (final smellId in targetSmellIds) {
          final alreadyExists = schedulesProvider.schedules.any(
            (schedule) =>
                schedule.smellId == smellId &&
                schedule.dayOfWeek == day &&
                schedule.startTime == _startTimeController.text.trim() &&
                schedule.endTime == _endTimeController.text.trim(),
          );

          if (alreadyExists) {
            continue;
          }

          await schedulesProvider.addSchedule(
            smellId: smellId,
            dayOfWeek: day,
            startTime: _startTimeController.text.trim(),
            endTime: _endTimeController.text.trim(),
            bleProvider: bleProvider,
          );
          addedCount++;
        }
      }

      if (addedCount == 0) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Ayni takvim zaten mevcut')), 
        );
        return;
      }
    } else {
      if (_selectedSmellId == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Duzenleme icin tek bir koku secin')),
        );
        return;
      }

      await schedulesProvider.updateSchedule(
        _editingScheduleId!,
        smellId: _selectedSmellId,
        dayOfWeek: _selectedDays.first,
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        bleProvider: bleProvider,
      );
    }

    await _syncDeviceConfig(bleProvider, schedulesProvider, smellsProvider);
    _resetForm();
  }

  Future<void> _deleteSchedule(
    String scheduleId,
    SchedulesProvider schedulesProvider,
    SmellsProvider smellsProvider,
  ) async {
    final bleProvider = context.read<BleProvider>();
    await schedulesProvider.deleteSchedule(scheduleId, bleProvider);
    await _syncDeviceConfig(bleProvider, schedulesProvider, smellsProvider);
    if (_editingScheduleId == scheduleId) {
      _resetForm();
    }
  }

  Widget _buildSmellChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF10B981),
      backgroundColor: Colors.white,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? Colors.white : const Color(0xFF0A0A0A),
        fontWeight: FontWeight.w600,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    String scheduleId,
    SchedulesProvider schedulesProvider,
    SmellsProvider smellsProvider,
  ) {
    final dialogNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Takvimi Sil'),
        content: const Text('Bu takvimi silmek istediginize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteSchedule(scheduleId, schedulesProvider, smellsProvider);
              if (mounted) dialogNavigator.pop();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Takvimler',
      body: Consumer2<SchedulesProvider, SmellsProvider>(
        builder: (context, schedulesProvider, smellsProvider, _) {
          final bleProvider = context.watch<BleProvider>();

          final smellMap = {
            for (final smell in smellsProvider.smells) smell.id: smell,
          };
          final visibleSchedules = _selectedSmellId == null
              ? schedulesProvider.schedules
              : schedulesProvider.schedules
                  .where((schedule) => schedule.smellId == _selectedSmellId)
                  .toList();
          final selectedSmell =
              _selectedSmellId == null ? null : smellMap[_selectedSmellId!];
            final canSubmit =
              smellsProvider.smells.isNotEmpty && schedulesProvider.schedules.isNotEmpty;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const SectionLabel(text: 'ADIM 3 / 3'),
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
                        'Takvim Studosu',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bleProvider.isConnected
                            ? 'Bir koku secin, takvimleri goruntuleyin ve duzenleyin.'
                            : 'Cevrimdisi duzenleyebilirsiniz. BLE baglaninca senkron olur.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildSmellChip(
                            context: context,
                            label: 'Tum',
                            selected: _selectedSmellId == null,
                            onTap: () => _selectSmell(null),
                          ),
                          for (final smell in smellsProvider.smells)
                            ChoiceChip(
                              label: Text(smell.name),
                              selected: _selectedSmellId == null || _selectedSmellId == smell.id,
                              onSelected: (_) => _selectSmell(smell.id),
                              selectedColor: const Color(0xFF10B981),
                              backgroundColor: Colors.white,
                              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: (_selectedSmellId == null || _selectedSmellId == smell.id)
                                    ? Colors.white
                                    : const Color(0xFF0A0A0A),
                                fontWeight: FontWeight.w600,
                              ),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: (_selectedSmellId == null || _selectedSmellId == smell.id)
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingScheduleId == null ? 'Takvim Ekle' : 'Takvimi Duzenle',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedSmell == null
                                ? 'Tum secili: eklenecek takvim tum kokulara uygulanir.'
                                : '${selectedSmell.name} icin takvim duzenleniyor.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Gun Secimi (coklu secim)',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(7, (index) {
                              final selected = _selectedDays.contains(index);
                              return ChoiceChip(
                                label: Text(_dayNames[index]),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    if (selected) {
                                      _selectedDays.remove(index);
                                    } else {
                                      _selectedDays.add(index);
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFF10B981),
                                backgroundColor: Colors.white,
                                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: selected ? Colors.white : const Color(0xFF0A0A0A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: selected
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _startTimeController,
                                  cursorColor: const Color(0xFF0A0A0A),
                                  style: const TextStyle(
                                    color: Color(0xFF0A0A0A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Baslangic Saati',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                    hintText: '08:00',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
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
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Zorunlu';
                                    final regex = RegExp(r'^\d{2}:\d{2}$');
                                    if (!regex.hasMatch(value!.trim())) return 'Format: SS:DD';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _endTimeController,
                                  cursorColor: const Color(0xFF0A0A0A),
                                  style: const TextStyle(
                                    color: Color(0xFF0A0A0A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Bitis Saati',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                    hintText: '18:00',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
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
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Zorunlu';
                                    final regex = RegExp(r'^\d{2}:\d{2}$');
                                    if (!regex.hasMatch(value!.trim())) return 'Format: SS:DD';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  label: _editingScheduleId == null ? 'Takvim Ekle' : 'Takvimi Guncelle',
                                  leadingIcon: Icon(
                                    _editingScheduleId == null ? Icons.add : Icons.save_outlined,
                                  ),
                                  isEnabled: selectedSmell != null,
                                  onPressed: () => _submitSchedule(
                                    schedulesProvider,
                                    smellsProvider,
                                  ),
                                ),
                              ),
                              if (_editingScheduleId != null) ...[
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: _resetForm,
                                  child: const Text('Iptal'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (smellsProvider.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_florist_rounded,
                          size: 64,
                          color: Color(0xFF0A0A0A),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Once koku ekleyin',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Takvimler kokulara baglidir. Once Kokular ekranindan bir koku olusturun.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else ...[
                  const SectionLabel(text: 'CIHAZ TAKVIMLERI'),
                  const SizedBox(height: 12),
                  if (visibleSchedules.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        _selectedSmellId == null
                            ? 'Henuz takvim yok. Yukaridan koku secin veya yeni koku ekleyin.'
                            : '${selectedSmell?.name ?? 'bu koku'} icin henuz takvim yok.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...visibleSchedules.map((schedule) {
                      final smell = smellMap[schedule.smellId];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _fillFormFromSchedule(schedule),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF111827),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.schedule_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        smell?.name ?? 'Bilinmeyen koku',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF0A0A0A),
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatDay(schedule.dayOfWeek)} • ${schedule.startTime} - ${schedule.endTime}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFF6B7280),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  color: const Color(0xFFEF4444),
                                  onPressed: () => _showDeleteConfirmDialog(
                                    schedule.id,
                                    schedulesProvider,
                                    smellsProvider,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],

                if (smellsProvider.isEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Kokular Ekranina Git',
                      leadingIcon: const Icon(Icons.local_florist_rounded),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/smells');
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Gonder',
                    isEnabled: canSubmit,
                    onPressed: () => _handleSubmit(
                      schedulesProvider,
                      smellsProvider,
                      context.read<BleProvider>(),
                    ),
                  ),
                ),

                if (!bleProvider.isConnected) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Adim 1: Baglanti Ekranina Don',
                      leadingIcon: const Icon(Icons.bluetooth_searching_rounded),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/connection');
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
