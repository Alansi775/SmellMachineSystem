/// Widget for selecting a day of the week.
///
/// Displays 7 buttons (Mon-Sun) with visual indication of selected day.
///
/// TODO: Implement selection state and callbacks
import 'package:flutter/material.dart';

class DayPicker extends StatefulWidget {
  final int selectedDay; // 0 = Monday, 6 = Sunday
  final Function(int day) onDaySelected;

  const DayPicker({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<DayPicker> createState() => _DayPickerState();
}

class _DayPickerState extends State<DayPicker> {
  static const List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        7,
        (index) => OutlinedButton(
          onPressed: () => widget.onDaySelected(index),
          style: OutlinedButton.styleFrom(
            backgroundColor: widget.selectedDay == index
                ? Colors.black
                : Colors.transparent,
          ),
          child: Text(
            dayLabels[index],
            style: TextStyle(
              color: widget.selectedDay == index ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
