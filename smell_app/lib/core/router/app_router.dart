/// Named routes configuration for the application.
///
/// This file defines all route names and route builders used throughout the app.
/// Using named routes provides centralized management and makes refactoring easier.
///
/// TODO: Implement route generation and GoRouter configuration
class AppRouter {
  // Route names as static constants
  static const String splash = '/';
  static const String connection = '/connection';
  static const String smells = '/smells';
  static const String addSmell = '/smells/add';
  static const String schedules = '/schedules';
  static const String addSchedule = '/schedules/add';
  static const String settings = '/settings';

  // No instances
  AppRouter._();

  /// Builds route configuration.
  /// TODO: Implement with GoRouter or Navigator 2.0 pattern
  static void configure() {
    // TODO: Setup route paths and screens
  }
}
