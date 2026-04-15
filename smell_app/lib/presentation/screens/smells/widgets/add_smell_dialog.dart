/// Dialog for adding a new smell to the device.
///
/// Provides a text field for entering the smell name and
/// buttons to confirm or cancel.
///
/// TODO: Implement input validation
/// TODO: Implement submission to device repository
import 'package:flutter/material.dart';

class AddSmellDialog extends StatefulWidget {
  final Function(String name) onAdd;

  const AddSmellDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddSmellDialog> createState() => _AddSmellDialogState();
}

class _AddSmellDialogState extends State<AddSmellDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Smell'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Smell Name',
          hintText: 'e.g., Lavender',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onAdd(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
