import 'package:flutter/foundation.dart';
import '../data/models/smell.dart';
import '../core/utils/logger.dart';
import 'package:uuid/uuid.dart';
import 'ble_provider.dart';

class SmellsProvider extends ChangeNotifier {
  List<Smell> _smells = [];

  List<Smell> get smells => List.unmodifiable(_smells);
  bool get isEmpty => _smells.isEmpty;
  int get count => _smells.length;

  void replaceAll(List<Smell> smells) {
    _smells = List<Smell>.from(smells);
    notifyListeners();
  }

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
      notifyListeners();
    } catch (e) {
      Logger.error('Error deleting smell: $e');
    }
  }

  Smell? findById(String id) {
    try {
      return _smells.firstWhere((smell) => smell.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clears all smells locally.
  void clear() {
    _smells.clear();
    notifyListeners();
  }
}
