import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/schedules_provider.dart';
import '../../../providers/smells_provider.dart';
import '../../../providers/ble_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';

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
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
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
