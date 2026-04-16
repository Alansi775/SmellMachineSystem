import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../providers/schedules_provider.dart';
import '../../../providers/smells_provider.dart';
import '../../../providers/ble_provider.dart';
import '../../../data/models/device_config.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';
import '../../../core/utils/logger.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSmellId;
  int _selectedDay = 0;
  final _startTimeController = TextEditingController(text: '08:00');
  final _endTimeController = TextEditingController(text: '18:00');

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  int _timeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  String? _getNextSmellName(
    SchedulesProvider schedulesProvider,
    SmellsProvider smellsProvider,
  ) {
    if (schedulesProvider.schedules.isEmpty || smellsProvider.smells.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final currentDay = (now.weekday + 6) % 7; // Monday=0
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
    final smell = smellsProvider.smells.where((s) => s.id == bestSmellId).firstOrNull;
    return smell?.name;
  }

  Future<void> _handleDone(
    SchedulesProvider schedulesProvider,
    SmellsProvider smellsProvider,
    BleProvider bleProvider,
  ) async {
    if (!bleProvider.isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device is not connected via Bluetooth')),
      );
      return;
    }

    final config = DeviceConfig(
      smells: smellsProvider.smells,
      schedules: schedulesProvider.schedules,
    );

    final payload = jsonEncode(config.toJson());
    Logger.info('Applying full config from Done: $payload');
    final ok = await bleProvider.sendConfig(payload);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to apply config on device')),
      );
      return;
    }

      await Future.delayed(const Duration(milliseconds: 400));

      final nextSmell = bleProvider.lastNextSmellName ??
        _getNextSmellName(schedulesProvider, smellsProvider);
      final deviceMessage = bleProvider.lastDeviceMessage;
    final message = nextSmell == null
        ? (deviceMessage ?? 'Configuration applied successfully')
        : 'Configuration applied. Next smell: $nextSmell';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    Navigator.of(context).pushReplacementNamed('/settings');
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _showAddScheduleDialog(
    SchedulesProvider schedulesProvider,
    SmellsProvider smellsProvider,
  ) {
    _selectedSmellId = null;
    _selectedDay = 0;
    _startTimeController.text = '08:00';
    _endTimeController.text = '18:00';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Schedule'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Smell selector
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSmellId,
                  hint: const Text('Select Smell'),
                  items: smellsProvider.smells.map((smell) {
                    return DropdownMenuItem(
                      value: smell.id,
                      child: Text(smell.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSmellId = value);
                  },
                ),
                const SizedBox(height: 16),

                // Day selector
                DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedDay,
                  items: List.generate(7, (index) {
                    return DropdownMenuItem(
                      value: index,
                      child: Text(_dayNames[index]),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDay = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Start time
                TextFormField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time (HH:mm)',
                    hintText: '08:00',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    final regex = RegExp(r'^\d{2}:\d{2}$');
                    if (!regex.hasMatch(value!)) return 'Format: HH:mm';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // End time
                TextFormField(
                  controller: _endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Time (HH:mm)',
                    hintText: '18:00',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    final regex = RegExp(r'^\d{2}:\d{2}$');
                    if (!regex.hasMatch(value!)) return 'Format: HH:mm';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate() && _selectedSmellId != null) {
                final bleProvider = context.read<BleProvider>();
                await schedulesProvider.addSchedule(
                  smellId: _selectedSmellId!,
                  dayOfWeek: _selectedDay,
                  startTime: _startTimeController.text,
                  endTime: _endTimeController.text,
                  bleProvider: bleProvider,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    String scheduleId,
    SchedulesProvider schedulesProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final bleProvider = context.read<BleProvider>();
              await schedulesProvider.deleteSchedule(scheduleId, bleProvider);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Schedules',
      body: Consumer2<SchedulesProvider, SmellsProvider>(
        builder: (context, schedulesProvider, smellsProvider, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const SectionLabel(text: 'STEP 3 OF 3'),
                const SizedBox(height: 24),

                if (schedulesProvider.isEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.schedule,
                        size: 64,
                        color: Color(0xFFF4F4F5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No schedules created yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 40),
                    ],
                  )
                else ...[
                  ...schedulesProvider.schedules.map((schedule) {
                    final smell = smellsProvider.smells
                        .where((s) => s.id == schedule.smellId)
                        .firstOrNull;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    smell?.name ?? 'Unknown',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_dayNames[schedule.dayOfWeek]} ${schedule.startTime}-${schedule.endTime}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: const Color(0xFFEF4444),
                              onPressed: () => _showDeleteConfirmDialog(
                                schedule.id,
                                schedulesProvider,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],

                if (!smellsProvider.isEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Add Schedule',
                      leadingIcon: const Icon(Icons.add),
                      onPressed: () => _showAddScheduleDialog(
                        schedulesProvider,
                        smellsProvider,
                      ),
                    ),
                  )
                else
                  Text(
                    'Add a smell first',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Done',
                    onPressed: () => _handleDone(
                      schedulesProvider,
                      smellsProvider,
                      context.read<BleProvider>(),
                    ),
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
