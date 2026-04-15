/// Reusable card widget for displaying a single smell.
///
/// Shows smell name and provides actions:
/// - Tap to select/highlight
/// - Swipe to delete
/// - Long-press to rename
///
/// TODO: Implement interactive behaviors
import 'package:flutter/material.dart';

class SmellCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const SmellCard({
    super.key,
    required this.name,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onRename,
              child: const Text('Rename'),
            ),
            PopupMenuItem(
              onTap: onDelete,
              child: const Text('Delete'),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
