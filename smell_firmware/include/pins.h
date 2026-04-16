/// ESP32-S3 GPIO pin assignments for SmellDevice.
///
/// Documents which GPIO pins are connected to fragrance dispensing mechanisms.
/// The device supports up to 8 bottles, each with its own relay/solenoid control pin.
///
/// ESP32-S3-WROOM-1 DevKit-C board pin mapping:
/// - USB connector is on the right
/// - GPIO numbering follows ESP32-S3 datasheet
///
/// TODO: Update pin assignments based on actual hardware connections

#pragma once

// Sprayer/solenoid control pins (GPIO outputs)
// Each pin controls one fragrance bottle's dispenser
static constexpr uint8_t SPRAYER_PIN_0 = 1;   // Sprayer bottle 0
static constexpr uint8_t SPRAYER_PIN_1 = 2;   // Sprayer bottle 1
static constexpr uint8_t SPRAYER_PIN_2 = 42;  // Sprayer bottle 2
static constexpr uint8_t SPRAYER_PIN_3 = 41;  // Sprayer bottle 3
static constexpr uint8_t SPRAYER_PIN_4 = 40;  // Sprayer bottle 4
static constexpr uint8_t SPRAYER_PIN_5 = 39;  // Sprayer bottle 5
static constexpr uint8_t SPRAYER_PIN_6 = 38;  // Sprayer bottle 6
static constexpr uint8_t SPRAYER_PIN_7 = 37;  // Sprayer bottle 7

// Array of all sprayer pins for easy iteration
static constexpr uint8_t SPRAYER_PINS[8] = {
    SPRAYER_PIN_0, SPRAYER_PIN_1, SPRAYER_PIN_2, SPRAYER_PIN_3,
    SPRAYER_PIN_4, SPRAYER_PIN_5, SPRAYER_PIN_6, SPRAYER_PIN_7,
};

// Status LED (optional, for visual feedback)
static constexpr uint8_t STATUS_LED_PIN = 48;  // GPIO 48 (varies by board)

// Button for manual reset/wipe (optional)
static constexpr uint8_t RESET_BUTTON_PIN = 0;  // GPIO 0 (boot button, optional)

// I2C OLED display pins (SSD1306)
// Update these if your display is wired to different GPIOs.
static constexpr uint8_t DISPLAY_SDA_PIN = 8;
static constexpr uint8_t DISPLAY_SCL_PIN = 9;
