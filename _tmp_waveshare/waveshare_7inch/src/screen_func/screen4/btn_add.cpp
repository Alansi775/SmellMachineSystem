#include "lvgl.h"
#include <ui.h>
#include "ui_events.h"
#include <Arduino.h>
#include <stdio.h>
#include "screen4_func.h"
#include <Preferences.h>

const char * rol = "January\nFebruary\nMarch\nApril\nMay\nJune\nJuly\nAugust\nSeptember\nOctober\nNovember\nDecember";

Preferences preferences;
int buttonCount = 0;

// NVS'deki tüm butonları okuma
int loadAllButtonsFromNVS(Button buttons[], int maxButtons) {
    preferences.begin("buttonData", true);  // Okuma modunda aç
    buttonCount = 0;
    for (int i = 1; i <= 10 && buttonCount < maxButtons; i++) {
        char key[15];
        sprintf(key, "button_%d", i);

        Button button;
        if (preferences.getBytes(key, &button, sizeof(Button)) != 0) {  // Veri varsa oku
            buttons[buttonCount++] = button;
        }
    }

    preferences.end();
    return buttonCount;  // Yüklenen toplam buton sayısını döndür
}

bool deleteButtonToNVS(int button_id) {
    preferences.begin("buttonData", false); // Open in write mode

    char key[15];
    sprintf(key, "button_%d", button_id); // Assuming button_id is 0-indexed

    // Remove the key if it exists
    if (preferences.isKey(key)) {
        preferences.remove(key);
        preferences.end();
        return true; // Successfully deleted
    }

    preferences.end();
    return false; // Key not found
}

bool saveButtonToNVS(const char* name, const char* func) {
    if (!preferences.begin("buttonData", false)) {
        LV_LOG_USER("Failed to initialize preferences");
        return false;
    }

    Button newButton = {0, "", false, ""}; // Yeni buton oluştur
    
    // Boş bir adres bulma
    bool result = false;
    for (int i = 1; i <= 10; i++) {
        char key[15];
        sprintf(key, "button_%d", i);

        if (!preferences.isKey(key)) { // Eğer anahtar yoksa
            // Buton bilgilerini ayarla
            newButton.id = i;
            strncpy(newButton.name, name, sizeof(newButton.name) - 1);
            strncpy(newButton.func, func, sizeof(newButton.func) - 1);
            newButton.name[sizeof(newButton.name) - 1] = '\0';
            newButton.func[sizeof(newButton.func) - 1] = '\0';
            
            preferences.putBytes(key, &newButton, sizeof(Button)); // Yeni butonu kaydet
            LV_LOG_USER("%d, %s, %d, %s", newButton.id, newButton.name, newButton.durum ? 1 : 0, newButton.func);
            
            result = true; // Başarılı kaydetme
            break;
        }
    }
    
    preferences.end(); // Tek bir end çağrısı
    return result;
}

void save_btn_event_cb(lv_event_t * e) {
    lv_obj_t * current_panel = static_cast<lv_obj_t *>(lv_event_get_user_data(e));

    // İlk input alanını al
    lv_obj_t * input = lv_obj_get_child(current_panel, 1); // İlk input
    lv_obj_t * roller = lv_obj_get_child(current_panel, 2); // Roller widget (roller 3. çocuk olabilir)

    // Check if input and roller exist
    if (input == NULL) {
        LV_LOG_USER("First input not found!");
        return;
    }
    if (roller == NULL) {
        LV_LOG_USER("Roller not found!");
        return;
    }

    // Retrieve text from the input field
    const char * text1 = lv_textarea_get_text(input);

    // Retrieve selected text from the roller
    char roller_text[32];
    lv_roller_get_selected_str(roller, roller_text, sizeof(roller_text));

    LV_LOG_USER("Text1: %s", text1);
    LV_LOG_USER("Roller Selected: %s", roller_text);

    // Save text1 and roller_text to NVS or any other storage
    bool saveResult = saveButtonToNVS(text1, roller_text);
    LV_LOG_USER("saveButtonToNVS result: %d", saveResult);

    if (saveResult) {
        LV_LOG_USER("Button saved successfully.");
        
        // preferences.end() çağrısı
        preferences.end();

        // Paneli kapat veya yeni ekrana geç
        if (lv_obj_is_valid(current_panel)) {
            LV_LOG_USER("Deleting panel...");
            lv_obj_del(current_panel); // Paneli kapat
        }
        
        LV_LOG_USER("Loading ui_Screen4...");
        create_unique_buttons();  
    } else {
        LV_LOG_USER("Save failed. All slots are full.");
    }
}

// Çıkış butonu için olay fonksiyonu
void close_btn_event_cb(lv_event_t * e) {
    lv_obj_t * panel = static_cast<lv_obj_t *>(lv_event_get_user_data(e)); // Kullanıcı verisi olarak paneli al
    lv_obj_del(panel); // Paneli kapat
}

// Giriş (input) olay fonksiyonu
void input_event_cb(lv_event_t * e) {
    lv_obj_t * kb = static_cast<lv_obj_t *>(lv_event_get_user_data(e)); // Klavyeyi al
    lv_obj_clear_flag(kb, LV_OBJ_FLAG_HIDDEN); // Klavyeyi görünür yap  
    lv_keyboard_set_textarea(kb, (lv_obj_t *)lv_event_get_target(e));
    lv_textarea_set_text((lv_obj_t *)lv_event_get_target(e), " ");
}

void create_input_panel(lv_obj_t * parent, const char * roller_options) {
    lv_obj_t * panel = lv_obj_create(parent);
    lv_obj_set_size(panel, 500, 400); // Panel boyutu
    lv_obj_align(panel, LV_ALIGN_CENTER, 0, 0); // Paneli ortala
    lv_obj_set_style_bg_color(panel, lv_color_hex(0x2E2E2E), 0); // Panel arka plan rengi
    lv_obj_set_style_border_color(panel, lv_color_hex(0x2E2E2E), 0); // Kenar rengi

    // Klavye oluştur
    lv_obj_t * kb = lv_keyboard_create(panel);
    lv_obj_add_flag(kb, LV_OBJ_FLAG_HIDDEN); // Klavyeyi başlangıçta gizle

    // İlk input
    lv_obj_t * input = lv_textarea_create(panel);
    lv_obj_set_size(input, 260, 40);
    lv_obj_align(input, LV_ALIGN_TOP_MID, 0, 130); // Panelin üst ortasına yerleştir
    lv_obj_add_event_cb(input, input_event_cb, LV_EVENT_CLICKED, kb); // Tıklama olayı ekle

    lv_textarea_set_text(input, "Name..");  

    static lv_style_t style;
    lv_style_init(&style);
    lv_style_set_bg_color(&style, lv_color_hex(0x2E2E2E));
    lv_style_set_text_color(&style, lv_color_white());
    lv_style_set_border_width(&style, 0);
    lv_style_set_pad_all(&style, 0);
    lv_obj_add_style(lv_scr_act(), &style, 0);

    // Roller widget
    lv_obj_t * roller = lv_roller_create(panel);
    lv_obj_add_style(roller, &style, 0);
    lv_obj_set_size(roller, 260, 60);  // Roller widget boyutu
    lv_obj_align(roller, LV_ALIGN_TOP_MID, 0, 0);  // İlk input'un altına yerleştir
    lv_obj_set_style_text_font(roller, &lv_font_montserrat_24, LV_PART_SELECTED);
    lv_roller_set_options(roller, roller_options, LV_ROLLER_MODE_NORMAL);
    lv_roller_set_visible_row_count(roller, 3);
    lv_obj_add_event_cb(roller, mask_event_cb, LV_EVENT_ALL, NULL);

    // Kayıt butonu
    lv_obj_t * save_btn = lv_imgbtn_create(panel);
    lv_imgbtn_set_src(save_btn, LV_IMGBTN_STATE_RELEASED, NULL, &ui_img_tick_png, NULL);
    lv_obj_set_height(save_btn, 64);
    lv_obj_set_width(save_btn, LV_SIZE_CONTENT);
    lv_obj_align(save_btn, LV_ALIGN_TOP_LEFT, 0, 0); // Sağ alt köşeye yerleştir
    
    // Çıkış butonu
    lv_obj_t * close_btn = lv_imgbtn_create(panel);
    lv_imgbtn_set_src(close_btn, LV_IMGBTN_STATE_RELEASED, NULL, &ui_img_eexit_png, NULL);
    lv_obj_set_height(close_btn, 64);
    lv_obj_set_width(close_btn, LV_SIZE_CONTENT);
    lv_obj_align(close_btn, LV_ALIGN_TOP_RIGHT, 0, 0);

    // Çıkış butonu tıklama olayı
    lv_obj_add_event_cb(close_btn, close_btn_event_cb, LV_EVENT_CLICKED, panel);
    
    // Kayıt butonu tıklama olayı
    lv_obj_add_event_cb(save_btn, save_btn_event_cb, LV_EVENT_CLICKED, panel);
}
// Maske olay işleyici fonksiyonu
static void mask_event_cb(lv_event_t * e) {
    lv_event_code_t code = lv_event_get_code(e);
    lv_obj_t * obj = lv_event_get_target(e);

    static int16_t mask_top_id = -1;
    static int16_t mask_bottom_id = -1;

    if (code == LV_EVENT_COVER_CHECK) {
        lv_event_set_cover_res(e, LV_COVER_RES_MASKED);
    }
    else if (code == LV_EVENT_DRAW_MAIN_BEGIN) {
        // Maske ekle
        const lv_font_t * font = lv_obj_get_style_text_font(obj, LV_PART_MAIN);
        lv_coord_t line_space = lv_obj_get_style_text_line_space(obj, LV_PART_MAIN);
        lv_coord_t font_h = lv_font_get_line_height(font);

        lv_area_t roller_coords;
        lv_obj_get_coords(obj, &roller_coords);

        lv_area_t rect_area;
        rect_area.x1 = roller_coords.x1;
        rect_area.x2 = roller_coords.x2;
        rect_area.y1 = roller_coords.y1;
        rect_area.y2 = roller_coords.y1 + (lv_obj_get_height(obj) - font_h - line_space) / 2;

        // Üst fade maske
        auto * fade_mask_top = static_cast<lv_draw_mask_fade_param_t *>(lv_mem_buf_get(sizeof(lv_draw_mask_fade_param_t)));
        lv_draw_mask_fade_init(fade_mask_top, &rect_area, LV_OPA_TRANSP, rect_area.y1, LV_OPA_COVER, rect_area.y2);
        mask_top_id = lv_draw_mask_add(fade_mask_top, NULL);

        // Alt fade maske
        rect_area.y1 = rect_area.y2 + font_h + line_space - 1;
        rect_area.y2 = roller_coords.y2;

        auto * fade_mask_bottom = static_cast<lv_draw_mask_fade_param_t *>(lv_mem_buf_get(sizeof(lv_draw_mask_fade_param_t)));
        lv_draw_mask_fade_init(fade_mask_bottom, &rect_area, LV_OPA_COVER, rect_area.y1, LV_OPA_TRANSP, rect_area.y2);
        mask_bottom_id = lv_draw_mask_add(fade_mask_bottom, NULL);
    }
    else if (code == LV_EVENT_DRAW_POST_END) {
        // Maskeleri kaldır
        auto * fade_mask_top = static_cast<lv_draw_mask_fade_param_t *>(lv_draw_mask_remove_id(mask_top_id));
        auto * fade_mask_bottom = static_cast<lv_draw_mask_fade_param_t *>(lv_draw_mask_remove_id(mask_bottom_id));
        lv_draw_mask_free_param(fade_mask_top);
        lv_draw_mask_free_param(fade_mask_bottom);
        lv_mem_buf_release(fade_mask_top);
        lv_mem_buf_release(fade_mask_bottom);
        mask_top_id = -1;
        mask_bottom_id = -1;
    }
}
