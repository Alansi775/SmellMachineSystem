/// Screen for creating or editing a schedule.
///
/// Provides form fields for:
/// - Selecting day of week
/// - Selecting start time
/// - Selecting end time
/// - Selecting which smell to spray
///
/// TODO: Implement form validation
/// TODO: Implement time/day picker integration
/// TODO: Implement submission to device repository
import 'package:flutter/material.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  // TODO: Initialize form fields and state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Schedule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TODO: Day picker widget
            const SizedBox(height: 16),
            // TODO: Time range picker widget
            const SizedBox(height: 16),
            // TODO: Smell selector dropdown
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                // TODO: Validate and submit
              },
              child: const Text('Save Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
