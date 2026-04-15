/// Sprayer control for fragrance dispensing.
///
/// Low-level GPIO control for solenoid/relay pins.
/// Each sprayer controls one fragrance bottle.

#pragma once

#include <Arduino.h>
#include <string>

/// Manages GPIO activation for fragrance dispensing solenoids.
class Sprayer {
public:
  /// Initialize GPIO pins for all 8 sprayers.
  /// Must call setup() before any spray operations.
  void setup();

  /// Activates a specific sprayer by smell ID.
  void spray(const std::string& smellId, uint16_t durationMs = 500);

  /// Gets the GPIO pin number for a given smell index.
  uint8_t getPinForSmellIndex(uint8_t index) const;

  /// Checks if a specific pin is currently active.
  bool isPinActive(uint8_t pin) const;

  /// Emergency stop - deactivates all sprayers immediately.
  void stopAll();

  /// Must be called from main loop() to handle spray timing.
  void update();

private:
  /// Activates a specific GPIO pin for spraying.
  void activatePin(uint8_t pin, uint16_t durationMs);

  /// Deactivates a specific GPIO pin.
  void deactivatePin(uint8_t pin);
};
