/// Display manager implementation.
///
/// Uses SSD1306 OLED over I2C when present, with serial fallback.

#include "display_manager.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "pins.h"

namespace {
constexpr uint8_t kOledWidth = 128;
constexpr uint8_t kOledHeight = 64;
constexpr int8_t kOledResetPin = -1;
constexpr uint8_t kOledAddress = 0x3C;
Adafruit_SSD1306 gDisplay(kOledWidth, kOledHeight, &Wire, kOledResetPin);
}  // namespace

void DisplayManager::setup() {
  initialized = true;
  statusLine = "Booting";
  dataLine = "Waiting for app";

  Wire.begin(DISPLAY_SDA_PIN, DISPLAY_SCL_PIN);

  displayAvailable = gDisplay.begin(SSD1306_SWITCHCAPVCC, kOledAddress);
  if (displayAvailable) {
    gDisplay.clearDisplay();
    gDisplay.setTextWrap(false);
    gDisplay.setTextColor(SSD1306_WHITE);
  }

  showWelcome();

  Serial.println("[Display] Initialized");
  Serial.println(displayAvailable ? "[Display] OLED online" : "[Display] OLED not detected, serial fallback");
}

void DisplayManager::showWelcome() {
  splashUntilMs = millis() + 2600;
  statusLine = "Welcome";
  dataLine = "Smell Device Ready";
  render();
}

void DisplayManager::setBleConnected(bool connected) {
  if (!initialized || bleConnected == connected) {
    return;
  }

  bleConnected = connected;
  statusLine = bleConnected ? "BLE connected" : "BLE waiting";
  transientLine = bleConnected ? "Phone paired successfully" : "Phone disconnected";
  transientUntilMs = millis() + 2500;

  if (bleConnected) {
    Serial.println("[Display] BLE: Connected");
  } else {
    Serial.println("[Display] BLE: Disconnected");
  }

  render();
}

void DisplayManager::showDataReceived(const std::string& payload) {
  if (!initialized) {
    return;
  }

  statusLine = "Data received";
  dataLine = "Bytes: " + std::to_string(payload.length());
  transientLine = "Payload synced from app";
  transientUntilMs = millis() + 2500;

  Serial.print("[Display] Data received bytes: ");
  Serial.println(payload.length());
  render();
}

void DisplayManager::showApplyResult(
  bool success,
  const std::string& nextSmellName,
  uint8_t dayOfWeek,
  const std::string& startTime
) {
  if (!initialized) {
    return;
  }

  if (!success) {
    statusLine = "Apply failed";
    transientLine = "Config save failed";
    transientUntilMs = millis() + 3000;
    Serial.println("[Display] Apply: FAILED");
    render();
    return;
  }

  statusLine = "Apply success";
  dataLine = "Profile active";
  transientLine = "Config stored on ESP32";
  transientUntilMs = millis() + 3000;

  Serial.println("[Display] Apply: SUCCESS");
  if (!nextSmellName.empty()) {
    Serial.print("[Display] Next smell: ");
    Serial.print(nextSmellName.c_str());
    Serial.print(" | ");
    Serial.print(dayName(dayOfWeek));
    Serial.print(" ");
    Serial.println(startTime.c_str());
  } else {
    Serial.println("[Display] Next smell: N/A");
  }

  setNextSmellStatus(!nextSmellName.empty(), nextSmellName, dayOfWeek, startTime, minutesUntilNext);
  render();
}

void DisplayManager::setNextSmellStatus(
  bool hasNext,
  const std::string& smell,
  uint8_t dayOfWeek,
  const std::string& startTime,
  int minutesUntil
) {
  hasNextSmell = hasNext;
  nextSmellName = smell;
  nextSmellDay = dayOfWeek;
  nextSmellTime = startTime;
  minutesUntilNext = minutesUntil;
}

void DisplayManager::update() {
  if (!initialized) {
    return;
  }

  if (millis() - lastHeartbeatMs < 5000) {
    return;
  }

  lastHeartbeatMs = millis();
  Serial.print("[Display] Heartbeat | BLE=");
  Serial.println(bleConnected ? "Connected" : "Disconnected");

  render();
}

void DisplayManager::render() {
  if (!displayAvailable) {
    return;
  }

  gDisplay.clearDisplay();

  if (millis() < splashUntilMs) {
    gDisplay.setTextSize(1);
    gDisplay.setCursor(0, 2);
    gDisplay.print("SMELL DEVICE");
    gDisplay.drawLine(0, 12, 127, 12, SSD1306_WHITE);
    gDisplay.setTextSize(2);
    gDisplay.setCursor(0, 20);
    gDisplay.print("Welcome");
    gDisplay.setTextSize(1);
    gDisplay.setCursor(0, 50);
    gDisplay.print("Hotel-grade scent control");
    gDisplay.display();
    return;
  }

  gDisplay.setTextSize(1);
  gDisplay.setCursor(0, 0);
  gDisplay.print("Smell Device");
  gDisplay.setCursor(90, 0);
  gDisplay.print(bleConnected ? "BLE ON" : "BLE OFF");
  gDisplay.drawLine(0, 10, 127, 10, SSD1306_WHITE);

  gDisplay.setCursor(0, 14);
  gDisplay.print(trimForLine(statusLine, 21).c_str());

  gDisplay.setCursor(0, 25);
  if (hasNextSmell) {
    gDisplay.print("Next: ");
    gDisplay.print(trimForLine(nextSmellName, 12).c_str());
  } else {
    gDisplay.print("Next: none");
  }

  gDisplay.setCursor(0, 36);
  if (hasNextSmell) {
    gDisplay.print(dayName(nextSmellDay));
    gDisplay.print(" ");
    gDisplay.print(trimForLine(nextSmellTime, 5).c_str());
  } else {
    gDisplay.print(trimForLine(dataLine, 21).c_str());
  }

  gDisplay.setCursor(0, 47);
  if (hasNextSmell && minutesUntilNext >= 0) {
    int h = minutesUntilNext / 60;
    int m = minutesUntilNext % 60;
    gDisplay.print("Starts in ");
    gDisplay.print(h);
    gDisplay.print("h ");
    gDisplay.print(m);
    gDisplay.print("m");
  } else if (hasNextSmell) {
    gDisplay.print("Starts in --");
  } else {
    gDisplay.print("Waiting schedule...");
  }

  const bool showTransient = !transientLine.empty() && millis() < transientUntilMs;
  gDisplay.drawLine(0, 58, 127, 58, SSD1306_WHITE);
  gDisplay.setCursor(0, 59);
  gDisplay.print(trimForLine(showTransient ? transientLine : dataLine, 21).c_str());

  gDisplay.display();
}

std::string DisplayManager::trimForLine(const std::string& input, size_t maxLen) const {
  if (input.length() <= maxLen) {
    return input;
  }
  if (maxLen < 4) {
    return input.substr(0, maxLen);
  }
  return input.substr(0, maxLen - 3) + "...";
}

const char* DisplayManager::dayName(uint8_t day) const {
  switch (day) {
    case 0: return "Monday";
    case 1: return "Tuesday";
    case 2: return "Wednesday";
    case 3: return "Thursday";
    case 4: return "Friday";
    case 5: return "Saturday";
    case 6: return "Sunday";
    default: return "Unknown";
  }
}
