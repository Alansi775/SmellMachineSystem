#include "usrcan.h"

uint32_t esp32_id = 0x407;

static TaskHandle_t s_canReceiveTaskHandle;
static void canReceiveTask(void *arg);

void startCanCommunication(void)
{
    xTaskCreate(canReceiveTask, "CAN Receive", 4096, NULL, 5, &s_canReceiveTaskHandle);
}

// CAN haberleşmesini başlat
void canInit() {
    twai_general_config_t g_config = TWAI_GENERAL_CONFIG_DEFAULT((gpio_num_t)CAN_TX_PIN, (gpio_num_t)CAN_RX_PIN, TWAI_MODE_NORMAL);
    twai_timing_config_t t_config = CAN_BAUDRATE;
    twai_filter_config_t f_config = TWAI_FILTER_CONFIG_ACCEPT_ALL();

    // CAN modülünü başlat
    esp_err_t err = twai_driver_install(&g_config, &t_config, &f_config);
    if (err != ESP_OK) {
        LV_LOG_USER("CAN driver installation failed");
        return;
    }

    err = twai_start();
    if (err != ESP_OK) {
        LV_LOG_USER("Failed to start CAN bus");
        return;
    }

    LV_LOG_USER("CAN bus initialized");
}

void serializeButton(const Button* button, uint8_t* buffer) {
    memcpy(buffer, button, sizeof(Button));
}

void deserializeButton(const uint8_t* buffer, Button& button) {
    memcpy(&button, buffer, sizeof(Button));
}

// Button yapısını CAN bus üzerinden gönder
void canSend(const Button* button) {
     uint8_t buffer[sizeof(Button)];
    serializeButton(button, buffer);
    size_t totalBytes = sizeof(Button);
    size_t bytesSent = 0;

    while (bytesSent < totalBytes) {
        twai_message_t message;
        message.identifier = esp32_id;
        message.data_length_code = (totalBytes - bytesSent > 8) ? 8 : totalBytes - bytesSent;
        memcpy(message.data, buffer + bytesSent, message.data_length_code);

        if (twai_transmit(&message, pdMS_TO_TICKS(1000)) != ESP_OK) {
            LV_LOG_USER("CAN send error");
        }

        // Mesajı formatlayıp LV_LOG_USER ile yazdır
        char logMsg[128];  // Yeterli boyutta bir buffer tanımlayın
        sprintf(logMsg, "CAN Message Sent - ID: %d, Length: %d, Data: ", message.identifier, message.data_length_code);
        
        // Mesaj verilerini ekleyin
        for (int i = 0; i < message.data_length_code; i++) {
            char temp[5];
            sprintf(temp, "%02X ", message.data[i]);  // Veriyi HEX formatında yazdır
            strcat(logMsg, temp);  // Mesajı birleştir
        }

        LV_LOG_USER("%s", logMsg);  // LVGL logunu yazdır

        bytesSent += message.data_length_code;
        delay(10); // Kısa bir bekleme
    }
}

void sendAllButtons(Button buttons[], size_t size) {
    for (size_t i = 0; i < size; i++) {
        canSend(&buttons[i]); // canSend fonksiyonunu, her bir Button'u işaretçi olarak geçirerek çağırın
        delay(100); // Her bir gönderim arasında kısa bir bekleme
    }
}

bool canReceive(Button &button) {
    uint8_t buffer[sizeof(Button)];
    size_t bytesReceived = 0;

    while (bytesReceived < sizeof(Button)) {
        twai_message_t message;
        if (twai_receive(&message, pdMS_TO_TICKS(100)) == ESP_OK) {
            memcpy(buffer + bytesReceived, message.data, message.data_length_code);
            bytesReceived += message.data_length_code;
        } else {
            LV_LOG_USER("CAN receive error or timeout");
            return false;
        }
    }

    deserializeButton(buffer, button);
    return true;
}

static void canReceiveTask(void *arg) {
    LV_LOG_USER("CAN Receive Task started");
    Button receivedButton;

    while (1) {
        if (canReceive(receivedButton)) {  // Burada `receivedButton` doğrudan geçiliyor
            LV_LOG_USER("Received Button ID: %d\n", receivedButton.id);
            LV_LOG_USER("Name: %s\n", receivedButton.name);
            LV_LOG_USER("Durum: %s\n", receivedButton.durum ? "true" : "false");
            LV_LOG_USER("Func: %s\n", receivedButton.func);
        }
        delay(10);
    }
}

// CAN haberleşmesini durdur
void canStop() {
    twai_stop();
    twai_driver_uninstall();
    LV_LOG_USER("CAN bus stopped");
}