/// Widget for selecting a time range (start/end times).
///
/// Provides two time pickers for selecting start and end times.
///
/// TODO: Implement time picker integration
/// TODO: Implement validation (start < end)
import 'package:flutter/material.dart';

class TimeRangePicker extends StatefulWidget {
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final Function(String start, String end) onTimeRangeChanged;

  const TimeRangePicker({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onTimeRangeChanged,
  });

  @override
  State<TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TODO: Implement start time picker
        TextField(
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Start Time',
            suffixIcon: Icon(Icons.access_time),
          ),
          onTap: () {
            // TODO: Show time picker
          },
        ),
        const SizedBox(height: 16),
        // TODO: Implement end time picker
        TextField(
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'End Time',
            suffixIcon: Icon(Icons.access_time),
          ),
          onTap: () {
            // TODO: Show time picker
          },
        ),
      ],
    );
  }
}
