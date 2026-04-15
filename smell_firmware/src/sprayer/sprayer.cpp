/// Sprayer implementation for GPIO-based solenoid control.
///
/// Activates solenoid valves connected to GPIO pins to dispense fragrance.

#include "sprayer.h"
#include "pins.h"
#include "config.h"

// Track active sprays with timestamps
struct ActiveSpray {
  uint8_t pin;
  unsigned long startTime;
  uint16_t duration;
};

static const int MAX_ACTIVE_SPRAYS = 8;
static ActiveSpray activeSprayList[MAX_ACTIVE_SPRAYS];
static int activeSprayCount = 0;

void Sprayer::setup() {
  Serial.println("[Sprayer] Initializing sprayer pins...");

  for (int i = 0; i < 8; i++) {
    pinMode(SPRAYER_PINS[i], OUTPUT);
    digitalWrite(SPRAYER_PINS[i], LOW);
    Serial.print("[Sprayer] Pin GPIO");
    Serial.print(SPRAYER_PINS[i]);
    Serial.println(" initialized");
  }

  Serial.println("[Sprayer] All sprayers ready");
}

void Sprayer::spray(const std::string& smellId, uint16_t durationMs) {
  // Map smell ID to index (for now, simple index-based)
  // In production, would lookup in config
  uint8_t index = atoi(smellId.c_str()) % 8;
  uint8_t pin = getPinForSmellIndex(index);

  Serial.print("[Sprayer] Activating smell ");
  Serial.print(smellId.c_str());
  Serial.print(" on GPIO");
  Serial.print(pin);
  Serial.print(" for ");
  Serial.print(durationMs);
  Serial.println("ms");

  activatePin(pin, durationMs);
}

uint8_t Sprayer::getPinForSmellIndex(uint8_t index) const {
  if (index < 8) {
    return SPRAYER_PINS[index];
  }
  return SPRAYER_PINS[0]; // Default to first pin
}

bool Sprayer::isPinActive(uint8_t pin) const {
  for (int i = 0; i < activeSprayCount; i++) {
    if (activeSprayList[i].pin == pin) {
      return true;
    }
  }
  return false;
}

void Sprayer::stopAll() {
  Serial.println("[Sprayer] Stopping all sprayers");
  for (int i = 0; i < 8; i++) {
    digitalWrite(SPRAYER_PINS[i], LOW);
  }
  activeSprayCount = 0;
}

void Sprayer::activatePin(uint8_t pin, uint16_t durationMs) {
  if (activeSprayCount < MAX_ACTIVE_SPRAYS) {
    digitalWrite(pin, HIGH);
    activeSprayList[activeSprayCount].pin = pin;
    activeSprayList[activeSprayCount].startTime = millis();
    activeSprayList[activeSprayCount].duration = durationMs;
    activeSprayCount++;
    Serial.print("[Sprayer] Pin GPIO");
    Serial.print(pin);
    Serial.println(" activated");
  }
}

void Sprayer::deactivatePin(uint8_t pin) {
  digitalWrite(pin, LOW);
  // Remove from active list
  for (int i = 0; i < activeSprayCount; i++) {
    if (activeSprayList[i].pin == pin) {
      // Shift remaining items
      for (int j = i; j < activeSprayCount - 1; j++) {
        activeSprayList[j] = activeSprayList[j + 1];
      }
      activeSprayCount--;
      break;
    }
  }
  Serial.print("[Sprayer] Pin GPIO");
  Serial.print(pin);
  Serial.println(" deactivated");
}

// Must be called from loop() to handle spray timing
void Sprayer::update() {
  unsigned long currentTime = millis();
  for (int i = 0; i < activeSprayCount; i++) {
    if (currentTime - activeSprayList[i].startTime >= activeSprayList[i].duration) {
      deactivatePin(activeSprayList[i].pin);
      i--; // Adjust index since count changed
    }
  }
}
