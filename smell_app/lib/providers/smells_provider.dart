import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../data/models/smell.dart';
import '../data/models/device_config.dart';
import '../core/utils/logger.dart';
import 'package:uuid/uuid.dart';
import 'ble_provider.dart';

class SmellsProvider extends ChangeNotifier {
  List<Smell> _smells = [];

  List<Smell> get smells => List.unmodifiable(_smells);
  bool get isEmpty => _smells.isEmpty;
  int get count => _smells.length;

  /// Adds a new smell to the device.
  Future<void> addSmell(String name, [BleProvider? bleProvider]) async {
    try {
      if (name.isEmpty) {
        Logger.error('Smell name cannot be empty');
        return;
      }

      const uuid = Uuid();
      final newSmell = Smell(
        id: uuid.v4(),
        name: name,
      );

      _smells.add(newSmell);
      Logger.info('Added smell: ${newSmell.name}');
      
      // Send updated config to device
      await _syncWithDevice(_smells, bleProvider);
      notifyListeners();
    } catch (e) {
      Logger.error('Error adding smell: $e');
    }
  }

  /// Updates an existing smell's name.
  Future<void> updateSmell(
    String id,
    String newName,
    [BleProvider? bleProvider]
  ) async {
    try {
      final index = _smells.indexWhere((s) => s.id == id);
      if (index >= 0) {
        _smells[index] = _smells[index].copyWith(name: newName);
        Logger.info('Updated smell: $newName');
        
        // Send updated config to device
        await _syncWithDevice(_smells, bleProvider);
        notifyListeners();
      }
    } catch (e) {
      Logger.error('Error updating smell: $e');
    }
  }

  /// Deletes a smell from the device.
  Future<void> deleteSmell(String id, [BleProvider? bleProvider]) async {
    try {
      _smells.removeWhere((s) => s.id == id);
      Logger.info('Deleted smell: $id');
      
      // Send updated config to device
      await _syncWithDevice(_smells, bleProvider);
      notifyListeners();
    } catch (e) {
      Logger.error('Error deleting smell: $e');
    }
  }

  /// Sends updated smells configuration to device via BLE.
  Future<void> _syncWithDevice(
    List<Smell> smells,
    [BleProvider? bleProvider]
  ) async {
    if (bleProvider == null || !bleProvider.isConnected) {
      Logger.warning('Device not connected, config not synced');
      return;
    }

    try {
      // Create JSON config
      final config = DeviceConfig(smells: smells);
      final jsonStr = _jsonEncode(config.toJson());
      
      Logger.info('Syncing config to device: $jsonStr');
      final success = await bleProvider.sendConfig(jsonStr);
      
      if (success) {
        Logger.info('Config synced successfully');
      } else {
        Logger.error('Failed to sync config');
      }
    } catch (e) {
      Logger.error('Error syncing with device: $e');
    }
  }

  /// Simple JSON encoder (since json_serializable not in pubspec)
  String _jsonEncode(Map<String, dynamic> json) {
    final smellsJson = (json['smells'] as List?)?.map((s) {
      return '{"id":"${s['id']}","name":"${s['name']}"}';
    }).toList() ?? [];

    final schedulesJson = (json['schedules'] as List?)?.map((sch) {
      return '{"id":"${sch['id']}","smellId":"${sch['smellId']}","dayOfWeek":${sch['dayOfWeek']},"startTime":"${sch['startTime']}","endTime":"${sch['endTime']}"}';
    }).toList() ?? [];

    return '{"smells":[${smellsJson.join(',')}],"schedules":[${schedulesJson.join(',')}]}';
  }

  /// Clears all smells locally.
  void clear() {
    _smells.clear();
    notifyListeners();
  }
}
