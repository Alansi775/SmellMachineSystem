import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Color? backgroundColor;
  final bool centerTitle;
  final bool showSettingsAction;

  const ResponsiveScaffold({
    required this.title,
    required this.body,
    this.backgroundColor,
    this.centerTitle = true,
    this.showSettingsAction = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.01,
          ),
        ),
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: showSettingsAction
            ? [
                IconButton(
                  tooltip: 'Kontrol Merkezi',
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                ),
              ]
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: body,
          ),
        ),
      ),
    );
  }
}
