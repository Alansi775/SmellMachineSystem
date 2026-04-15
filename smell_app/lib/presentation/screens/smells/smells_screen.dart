import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/smells_provider.dart';
import '../../../providers/ble_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';

class SmellsScreen extends StatefulWidget {
  const SmellsScreen({super.key});

  @override
  State<SmellsScreen> createState() => _SmellsScreenState();
}

class _SmellsScreenState extends State<SmellsScreen> {
  final _smellNameController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _smellNameController.dispose();
    super.dispose();
  }

  void _showAddSmellDialog(SmellsProvider smellsProvider) {
    _smellNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Smell'),
        content: TextField(
          controller: _smellNameController,
          decoration: const InputDecoration(
            hintText: 'Enter smell name',
            labelText: 'Smell Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final bleProvider = context.read<BleProvider>();
              await smellsProvider.addSmell(
                _smellNameController.text,
                bleProvider,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    String smellId,
    SmellsProvider smellsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Smell'),
        content: const Text('Are you sure you want to delete this smell?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final bleProvider = context.read<BleProvider>();
              await smellsProvider.deleteSmell(smellId, bleProvider);
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
      title: 'Smells',
      body: Consumer<SmellsProvider>(
        builder: (context, smellsProvider, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const SectionLabel(text: 'STEP 2 OF 3'),
                const SizedBox(height: 24),

                if (smellsProvider.isEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.local_florist,
                        size: 64,
                        color: Color(0xFFF4F4F5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No smells added yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 40),
                    ],
                  )
                else ...[
                  ...smellsProvider.smells.map((smell) {
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
                                    smell.name,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    smell.id,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: const Color(0xFFEF4444),
                              onPressed: () =>
                                  _showDeleteConfirmDialog(smell.id, smellsProvider),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],

                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Add Smell',
                    leadingIcon: const Icon(Icons.add),
                    onPressed: () => _showAddSmellDialog(smellsProvider),
                    isLoading: _isAdding,
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Next: Schedules',
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
