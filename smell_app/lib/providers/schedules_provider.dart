import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../data/models/schedule.dart';
import '../data/models/device_config.dart';
import '../core/utils/logger.dart';
import 'package:uuid/uuid.dart';
import 'ble_provider.dart';

class SchedulesProvider extends ChangeNotifier {
  List<Schedule> _schedules = [];

  List<Schedule> get schedules => List.unmodifiable(_schedules);
  bool get isEmpty => _schedules.isEmpty;
  int get count => _schedules.length;

  /// Adds a new schedule to the device.
  Future<void> addSchedule({
    required String smellId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    BleProvider? bleProvider,
  }) async {
    try {
      // Validate inputs
      if (dayOfWeek < 0 || dayOfWeek > 6) {
        Logger.error('Invalid day of week: $dayOfWeek');
        return;
      }
      if (!_isValidTimeFormat(startTime) || !_isValidTimeFormat(endTime)) {
        Logger.error('Invalid time format. Use HH:mm');
        return;
      }

      const uuid = Uuid();
      final newSchedule = Schedule(
        id: uuid.v4(),
        smellId: smellId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );

      _schedules.add(newSchedule);
      Logger.info('Added schedule: $smellId at $startTime-$endTime');
      
      // Send updated config to device
      await _syncWithDevice(_schedules, bleProvider: bleProvider);
      notifyListeners();
    } catch (e) {
      Logger.error('Error adding schedule: $e');
    }
  }

  /// Updates an existing schedule.
  Future<void> updateSchedule(
    String id, {
    String? smellId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    BleProvider? bleProvider,
  }) async {
    try {
      final index = _schedules.indexWhere((s) => s.id == id);
      if (index >= 0) {
        final current = _schedules[index];
        _schedules[index] = Schedule(
          id: id,
          smellId: smellId ?? current.smellId,
          dayOfWeek: dayOfWeek ?? current.dayOfWeek,
          startTime: startTime ?? current.startTime,
          endTime: endTime ?? current.endTime,
        );
        Logger.info('Updated schedule: $id');
        
        // Send updated config to device
        await _syncWithDevice(_schedules, bleProvider: bleProvider);
        notifyListeners();
      }
    } catch (e) {
      Logger.error('Error updating schedule: $e');
    }
  }

  /// Deletes a schedule from the device.
  Future<void> deleteSchedule(
    String id,
    [BleProvider? bleProvider]
  ) async {
    try {
      _schedules.removeWhere((s) => s.id == id);
      Logger.info('Deleted schedule: $id');
      
      // Send updated config to device
      await _syncWithDevice(_schedules, bleProvider: bleProvider);
      notifyListeners();
    } catch (e) {
      Logger.error('Error deleting schedule: $e');
    }
  }

  /// Gets schedules for a specific day.
  List<Schedule> getSchedulesForDay(int dayOfWeek) {
    return _schedules.where((s) => s.dayOfWeek == dayOfWeek).toList();
  }

  /// Sends updated schedules configuration to device via BLE.
  Future<void> _syncWithDevice(
    List<Schedule> schedules,
    {BleProvider? bleProvider}
  ) async {
    if (bleProvider == null || !bleProvider.isConnected) {
      Logger.warning('Device not connected, schedules not synced');
      return;
    }

    try {
      // Get current smells from app context (requires inject)
      // For now, just send schedules
      final config = DeviceConfig(
        smells: [],
        schedules: schedules,
      );
      final jsonStr = _jsonEncode(config.toJson());
      
      Logger.info('Syncing schedules to device: $jsonStr');
      final success = await bleProvider.sendConfig(jsonStr);
      
      if (success) {
        Logger.info('Schedules synced successfully');
      } else {
        Logger.error('Failed to sync schedules');
      }
    } catch (e) {
      Logger.error('Error syncing with device: $e');
    }
  }

  /// Validates time format HH:mm.
  bool _isValidTimeFormat(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return false;
    try {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour >= 0 && hour < 24 && minute >= 0 && minute < 60;
    } catch (e) {
      return false;
    }
  }

  /// Simple JSON encoder.
  String _jsonEncode(Map<String, dynamic> json) {
    final smellsJson = (json['smells'] as List?)?.map((s) {
      return '{"id":"${s['id']}","name":"${s['name']}"}';
    }).toList() ?? [];

    final schedulesJson = (json['schedules'] as List?)?.map((sch) {
      return '{"id":"${sch['id']}","smellId":"${sch['smellId']}","dayOfWeek":${sch['dayOfWeek']},"startTime":"${sch['startTime']}","endTime":"${sch['endTime']}"}';
    }).toList() ?? [];

    return '{"smells":[${smellsJson.join(',')}],"schedules":[${schedulesJson.join(',')}]}';
  }

  /// Clears all schedules locally.
  void clear() {
    _schedules.clear();
    notifyListeners();
  }
}
