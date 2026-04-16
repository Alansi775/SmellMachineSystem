#include <Arduino.h>
#include <lvgl.h>
#include <ESP_Panel_Library.h>
#include <ESP_IOExpander_Library.h>
#include <ui.h>
#include "SPI.h"
#include <string>
#include "ui_events.h"

#include "screen_func/screen1/screen1_func.h"
#include "screen_func/screen2/screen2_func.h"
#include "screen_func/screen3/screen3_func.h"
#include "screen_func/screen4/screen4_func.h"

#include "screen_func/alerts/alert.h"
#include "canBus/usrCan.h"

// SD Kart tanımı
#define SD_MOSI 11
#define SD_CLK  12
#define SD_MISO 13
#define SD_SS -1

// IO Pin tanımı
#define TP_RST 1
#define LCD_BL 2
#define LCD_RST 3
#define SD_CS 4
#define USB_SEL 5

// I2C Pin tanımı
#define I2C_MASTER_NUM 0
// #define I2C_MASTER_NUM I2C_NUM_0
#define I2C_MASTER_SDA_IO 8
#define I2C_MASTER_SCL_IO 9

/*  LVGL konfigurasyon yapılandırmaları */
#define LVGL_TICK_PERIOD_MS     (2)
#define LVGL_TASK_MAX_DELAY_MS  (500)
#define LVGL_TASK_MIN_DELAY_MS  (1)
#define LVGL_TASK_STACK_SIZE    (4 * 1024)
#define LVGL_TASK_PRIORITY      (2)
#define LVGL_BUF_SIZE           (ESP_PANEL_LCD_H_RES * 20)

ESP_Panel *panel = NULL;
SemaphoreHandle_t lvgl_mux = NULL;  // LVGL kilit sistemi (mutex)

#if ESP_PANEL_LCD_BUS_TYPE == ESP_PANEL_BUS_TYPE_RGB
/* Ekran yenileme (flush) fonksiyonu */
void lvgl_port_disp_flush(lv_disp_drv_t *disp, const lv_area_t *area, lv_color_t *color_p)
{
    panel->getLcd()->drawBitmap(area->x1, area->y1, area->x2 + 1, area->y2 + 1, color_p);
    lv_disp_flush_ready(disp);  // Yenileme işlemi tamamlandı sinyali
}
#else
/* Ekran yenileme (flush) fonksiyonu */
void lvgl_port_disp_flush(lv_disp_drv_t *disp, const lv_area_t *area, lv_color_t *color_p)
{
    panel->getLcd()->drawBitmap(area->x1, area->y1, area->x2 + 1, area->y2 + 1, color_p);
}

bool notify_lvgl_flush_ready(void *user_ctx)
{
    lv_disp_drv_t *disp_driver = (lv_disp_drv_t *)user_ctx;
    lv_disp_flush_ready(disp_driver);
    return false;
}
#endif /* ESP_PANEL_LCD_BUS_TYPE */

#if ESP_PANEL_USE_LCD_TOUCH
/* Dokunmatik ekran verilerini okuma fonksiyonu */
void lvgl_port_tp_read(lv_indev_drv_t * indev, lv_indev_data_t * data)
{
    panel->getLcdTouch()->readData();  // Dokunmatik verileri oku

    bool touched = panel->getLcdTouch()->getTouchState();  // Ekrana dokunulmuş mu kontrol et
    if (!touched) {
        data->state = LV_INDEV_STATE_REL;  // Dokunma yoksa serbest (released) durumunda
    } else {
        TouchPoint point = panel->getLcdTouch()->getPoint();  // Dokunma varsa koordinatları al

        data->state = LV_INDEV_STATE_PR;  // Dokunma var (pressed) durumunda
        /* Koordinatları ayarla */
        data->point.x = point.x;
        data->point.y = point.y;

        Serial.printf("Dokunma noktası: x %d, y %d\n", point.x, point.y);  // Koordinatları seri port ekranına yaz
    }
}
#endif

void lvgl_port_lock(int timeout_ms)
{
    const TickType_t timeout_ticks = (timeout_ms < 0) ? portMAX_DELAY : pdMS_TO_TICKS(timeout_ms);
    xSemaphoreTakeRecursive(lvgl_mux, timeout_ticks);  // Mutex kilitleme
}

void lvgl_port_unlock(void)
{
    xSemaphoreGiveRecursive(lvgl_mux);  // Mutex serbest bırakma
}

void lvgl_port_task(void *arg)
{
    Serial.println("LVGL görevi başlatılıyor");

    uint32_t task_delay_ms = LVGL_TASK_MAX_DELAY_MS;
    while (1) {
        // LVGL API'leri thread güvenli olmadığı için mutex kilitleme
        lvgl_port_lock(-1);
        task_delay_ms = lv_timer_handler();  // LVGL zamanlayıcıyı çalıştır
        lvgl_port_unlock();  // Mutex serbest bırakma
        if (task_delay_ms > LVGL_TASK_MAX_DELAY_MS) {
            task_delay_ms = LVGL_TASK_MAX_DELAY_MS;
        } else if (task_delay_ms < LVGL_TASK_MIN_DELAY_MS) {
            task_delay_ms = LVGL_TASK_MIN_DELAY_MS;
        }
        vTaskDelay(pdMS_TO_TICKS(task_delay_ms));  // Görevi geciktirme
    }
}

Button buttonsToSend[6] = {
        {1, "HARRY POTTER", true, "isik"},
        {2, "Hermione Granger", false, "fan"},
        {3, "Ron Weasley", false, "isik"},
        {4, "Albus Dumbledore", false, "anahtar"},
        {5, "Severus Snape", true, "fan"},
        {6, "Silvus Black", true, "anahtar"}
      };

void setup() {
    Serial.begin(115200);  // Seri haberleşme başlatılıyor

    String LVGL_Arduino = "Merhaba LVGL! ";
    LVGL_Arduino += String('V') + lv_version_major() + "." + lv_version_minor() + "." + lv_version_patch();  // LVGL sürüm numarasını al

    Serial.println(LVGL_Arduino);  // Seri porttan LVGL versiyonu yazdırılıyor
    Serial.println("Ben ESP32_Display_Panel");

    panel = new ESP_Panel();  // Yeni panel nesnesi oluşturuluyor

    /* LVGL çekirdeğini başlat */
    lv_init();

    /* LVGL tamponlarını başlat */
    static lv_disp_draw_buf_t draw_buf;
    uint8_t *buf = (uint8_t *)heap_caps_calloc(1, LVGL_BUF_SIZE * sizeof(lv_color_t), MALLOC_CAP_INTERNAL);  // Bellek ayırma
    assert(buf);  // Bellek başarıyla ayrıldı mı kontrol et
    lv_disp_draw_buf_init(&draw_buf, buf, NULL, LVGL_BUF_SIZE);  // Çizim tamponunu başlat

    /* Ekran cihazını başlat */
    static lv_disp_drv_t disp_drv;
    lv_disp_drv_init(&disp_drv);  // Ekran sürücüsünü başlat
    disp_drv.hor_res = ESP_PANEL_LCD_H_RES;  // Yatay çözünürlük
    disp_drv.ver_res = ESP_PANEL_LCD_V_RES;  // Dikey çözünürlük
    disp_drv.flush_cb = lvgl_port_disp_flush;  // Yenileme (flush) fonksiyonu
    disp_drv.draw_buf = &draw_buf;  // Çizim tamponunu ekrana atam
    lv_disp_drv_register(&disp_drv);  // Ekran sürücüsünü kaydet

#if ESP_PANEL_USE_LCD_TOUCH
    /* Giriş cihazını başlat (dokunmatik ekran) */
    static lv_indev_drv_t indev_drv;
    lv_indev_drv_init(&indev_drv);  // Giriş cihazı sürücüsünü başlat
    indev_drv.type = LV_INDEV_TYPE_POINTER;  // Giriş cihazı tipi: Pointer (dokunmatik)
    indev_drv.read_cb = lvgl_port_tp_read;  // Dokunma okuma fonksiyonu
    lv_indev_drv_register(&indev_drv);  // Giriş cihazı sürücüsünü kaydet
#endif

    /* Panelin veri yolu ve cihazını başlat */
    panel->init();

#if ESP_PANEL_LCD_BUS_TYPE != ESP_PANEL_BUS_TYPE_RGB
    panel->getLcd()->setCallback(notify_lvgl_flush_ready, &disp_drv);  // Yenileme (flush) tamamlandığında LVGL'yi bilgilendir
#endif

    /* IO genişleticiyi başlat ve panele ekle */
    Serial.println("IO genişletici başlatılıyor");
    // ESP_IOExpander *expander = new ESP_IOExpander_CH422G(I2C_MASTER_NUM, ESP_IO_EXPANDER_I2C_CH422G_ADDRESS_000);  // IO genişletici nesnesi
    ESP_IOExpander *expander = new ESP_IOExpander_CH422G((i2c_port_t)I2C_MASTER_NUM, ESP_IO_EXPANDER_I2C_CH422G_ADDRESS_000, I2C_MASTER_SCL_IO, I2C_MASTER_SDA_IO);
    expander->init();  // IO genişletici başlatılıyor
    expander->begin();  // Genişletici başlatılıyor
    expander->multiPinMode(TP_RST | LCD_BL | LCD_RST | SD_CS | USB_SEL, OUTPUT);  // IO genişletici pin modları
    expander->multiDigitalWrite(TP_RST | LCD_BL | LCD_RST | SD_CS, HIGH);  // Pinlere dijital sinyal gönder

    expander->digitalWrite(USB_SEL, HIGH);  // USB seçme pini kapalı
    panel->addIOExpander(expander);  // Genişletici panele ekleniyor

    /* Panel başlatılıyor */
    panel->begin();

    // initCAN();
    // startCanCommunication();

    canInit();
    startCanCommunication();
    // sendAllButtons(buttonsToSend, sizeof(buttonsToSend) / sizeof(buttonsToSend[0]));

    /* LVGL görevini periyodik olarak çalıştıracak bir görev oluştur */
    lvgl_mux = xSemaphoreCreateRecursiveMutex();  // Mutex oluşturuluyor
    xTaskCreate(lvgl_port_task, "lvgl", LVGL_TASK_STACK_SIZE, NULL, LVGL_TASK_PRIORITY, NULL);  // LVGL görevini başlat

    /* LVGL API'leri thread güvenli olmadığı için mutex kilitle */
    lvgl_port_lock(-1);
    ui_init();

    /* Mutex'i serbest bırak */
    lvgl_port_unlock();

    create_multiple_battery_cells(ui_Screen1, 3);
    update_battery_cell(1, 5);
    update_battery_cell(2, 50);

    create_multiple_temizsu_depo(ui_Screen2, 3);
    update_temizsu_depo(1, 20);
    update_temizsu_depo(2, 80);

    create_multiple_Kirlisu_depo(ui_Screen2, 3);
    update_Kirlisu_depo(1, 5);
    update_Kirlisu_depo(2, 60);

    create_multiple_fuel_cells(ui_Screen3, 4);
    update_fuel_cell(0, 5);
    update_fuel_cell(1, 60);
    update_fuel_cell(2, 30);
    update_fuel_cell(3, 90);
    
    create_unique_buttons();

    // alert_battery_main();
    // alert_water_main();
    // alert_fuel_main();  

    Serial.println("Kurulum tamamlandı");
}

void loop()
{
 sleep(1);  // 10 saniye bekle
}
