#ifndef USRCAN_H
#define USRCAN_H

#include <Arduino.h>
#include <driver/twai.h>
#include "esp_err.h"
#include <lvgl.h>
#include "freertos/queue.h"
#include "screen_func/screen4/screen4_func.h"

// CAN baudrate configuration
#define CAN_BAUDRATE    TWAI_TIMING_CONFIG_500KBITS()

// CAN pinleri
#define CAN_RX_PIN 19
#define CAN_TX_PIN 20

// Fonksiyonlar
void canInit();
void canSend(const Button* button);
void sendAllButtons(Button buttons[], size_t size);
bool canReceive(Button &button);
void canStop();

void startCanCommunication(void);

#endif // USRCAN_H
