/// Widget displaying a single BLE device as a selectable tile.
///
/// Shows device name and connection status, with tap to select.
///
/// TODO: Implement device selection callback
/// TODO: Implement status indicator
import 'package:flutter/material.dart';

class DeviceTile extends StatelessWidget {
  final String name;
  final String id;
  final bool isConnected;
  final VoidCallback onTap;

  const DeviceTile({
    super.key,
    required this.name,
    required this.id,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text(id),
      trailing: isConnected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}
