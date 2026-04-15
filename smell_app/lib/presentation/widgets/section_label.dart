import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const SectionLabel({
    required this.text,
    this.color = const Color(0xFFA1A1AA),
    this.fontSize = 11.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    );
  }
}
