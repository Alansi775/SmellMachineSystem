import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/locale_provider.dart';
import 'providers/ble_provider.dart';
import 'providers/smells_provider.dart';
import 'providers/schedules_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/connection/connection_screen.dart';
import 'presentation/screens/smells/smells_screen.dart';
import 'presentation/screens/schedules/schedules_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

class SmellDeviceApp extends StatelessWidget {
  const SmellDeviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => BleProvider()),
        ChangeNotifierProvider(create: (_) => SmellsProvider()),
        ChangeNotifierProvider(create: (_) => SchedulesProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Smell Device',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: localeProvider.locale,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            routes: {
              '/connection': (context) => const ConnectionScreen(),
              '/smells': (context) => const SmellsScreen(),
              '/schedules': (context) => const SchedulesScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
