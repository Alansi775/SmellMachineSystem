import 'dart:ui';

import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Color? backgroundColor;
  final bool centerTitle;
  final bool showSettingsAction;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.backgroundColor,
    this.centerTitle = true,
    this.showSettingsAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
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
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF111827) : Colors.white).withValues(
                  alpha: isDark ? 0.72 : 0.62,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: (isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFE5E7EB))
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: showSettingsAction
            ? [
                IconButton(
                  tooltip: 'Kontrol Merkezi',
                  icon: const Icon(Icons.settings_rounded),
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
