/// Reusable card widget for displaying a single schedule.
///
/// Shows day, time range, and smell name in an elegant format.
///
/// TODO: Implement tap handling for editing
/// TODO: Implement swipe-to-delete
import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String dayName;
  final String timeRange;
  final String smellName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ScheduleCard({
    super.key,
    required this.dayName,
    required this.timeRange,
    required this.smellName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(dayName),
        subtitle: Text('$timeRange - $smellName'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
