#include "lvgl.h"
#include <ui.h>
#include "ui_events.h"
#include <Arduino.h>
#include <stdio.h>
#include "screen4_func.h"

#define MAX_BUTTON_COUNT 10
lv_obj_t * button_list[MAX_BUTTON_COUNT];
lv_obj_t * name_labels[MAX_BUTTON_COUNT]; // Global array to track label objects
Button buttonsData[MAX_BUTTON_COUNT];
#define LONG_PRESS_THRESHOLD 2000

static int32_t press_start_time = -1;
bool button_states[MAX_BUTTON_COUNT] = {false};

void button_event_handler(lv_event_t * e) {
    lv_event_code_t event_code = lv_event_get_code(e);
    lv_obj_t * target = lv_event_get_target(e);
    int button_id = (intptr_t)lv_event_get_user_data(e);
    button_id += 1;

    if (event_code == LV_EVENT_CLICKED) {
        if (!button_states[button_id]) {
            lv_obj_set_style_shadow_width(target, 20, LV_PART_MAIN | LV_STATE_DEFAULT);
            lv_obj_set_style_shadow_spread(target, 20, LV_PART_MAIN | LV_STATE_DEFAULT);
            lv_obj_set_style_shadow_color(target, lv_color_hex(0x140f42), LV_PART_MAIN | LV_STATE_DEFAULT);
            lv_obj_set_style_bg_color(target, lv_color_hex(0x140f42), LV_PART_MAIN | LV_STATE_DEFAULT);
            lv_obj_set_style_bg_opa(target, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
            button_states[button_id] = true;
        } else {
            lv_obj_set_style_shadow_width(target, 1, LV_PART_MAIN | LV_STATE_DEFAULT);
            lv_obj_set_style_shadow_spread(target, 0, LV_PART_MAIN | LV_STATE_DEFAULT);
            lv_obj_set_style_shadow_color(target, lv_color_hex(0x291C73), LV_PART_MAIN | LV_STATE_DEFAULT);
            lv_obj_set_style_bg_opa(target, 0, LV_PART_MAIN | LV_STATE_DEFAULT);
            button_states[button_id] = false;
        }
    } else if (event_code == LV_EVENT_PRESSING) {
        if (press_start_time == -1) {
            press_start_time = lv_tick_get();
        }

        if (lv_tick_get() - press_start_time > LONG_PRESS_THRESHOLD) {
            LV_LOG_USER("Button %d long pressed!", button_id);
            lv_coord_t x = lv_obj_get_x(target);
            lv_coord_t y = lv_obj_get_y(target);
            displayDeleteConfirmationButton(button_id, x, y);
            press_start_time = -1;
        }
    } else if (event_code == LV_EVENT_RELEASED) {
        press_start_time = -1;
    }
}

void displayDeleteConfirmationButton(int button_id, int x, int y) {
    lv_obj_t * confirm_btn = lv_btn_create(lv_scr_act());
    lv_obj_set_size(confirm_btn, 120, 50);

    lv_obj_set_x(confirm_btn, x - 10);
    lv_obj_set_y(confirm_btn, y - 10);

    lv_obj_t * label = lv_label_create(confirm_btn);
    lv_label_set_text(label, "Delete Button");
    lv_obj_center(label);

    lv_obj_add_event_cb(confirm_btn, confirm_btn_event_handler, LV_EVENT_CLICKED, (void *)(intptr_t)button_id);
}

void confirm_btn_event_handler(lv_event_t * e) {
    lv_obj_t * btn = lv_event_get_target(e);
    int button_id = (intptr_t)lv_event_get_user_data(e);

    // Delete the button and its label
    if (deleteButtonToNVS(button_id)) {
        LV_LOG_USER("Button %d deleted successfully!", button_id);
        lv_obj_del(button_list[button_id-1]);  // Delete the button itself
        lv_obj_del(name_labels[button_id-1]);  // Delete the associated label

        lv_obj_del(btn); // Delete confirmation button
        create_unique_buttons();  
        // lv_obj_invalidate(lv_scr_act()); // Refresh screen to update layout
    } else {
        LV_LOG_USER("Failed to delete button %d!", button_id);
    }
}

lv_obj_t  *btn_container;
void create_unique_buttons() {
    int button_width = 100;
    int button_height = 100;
    int start_x = 30;
    int start_y = 30;
    int spacing_x = 60;
    int spacing_y = 60;
    int col_count = 5;
    
    if (btn_container != NULL) {
        lv_obj_del(btn_container);  // Tüm nesneyi sil
        btn_container = NULL;       // Null'a ayarla
        LV_LOG_USER("btn_container silindi ve yeniden oluşturulacak.");
    }
    btn_container  = lv_obj_create(ui_Screen4);
    lv_obj_remove_style_all(btn_container);
    lv_obj_set_width(btn_container, 800);
    lv_obj_set_height(btn_container, 300);
    lv_obj_set_align(btn_container , LV_ALIGN_CENTER);    
    lv_obj_clear_flag(btn_container, LV_OBJ_FLAG_SCROLLABLE);

    memset(buttonsData, 0, sizeof(buttonsData));
    memset(button_list, 0, sizeof(button_list)); 
    memset(name_labels, 0, sizeof(name_labels)); 

    // EEPROM'dan buton bilgilerini oku
    int button_count = loadAllButtonsFromNVS(buttonsData, MAX_BUTTON_COUNT);
    LV_LOG_USER("Button count from NVS: %d", button_count);
    
    // Her bir buton için döngü
    for (int i = 0; i < button_count; i++) {
        int btn_x = start_x + (i % col_count) * (button_width + spacing_x);
        int btn_y = start_y + (i / col_count) * (button_height + spacing_y);

        // Yeni buton oluştur
        button_list[i] = lv_btn_create(btn_container);
        lv_obj_set_width(button_list[i], button_width);
        lv_obj_set_height(button_list[i], button_height);
        lv_obj_set_x(button_list[i], btn_x);
        lv_obj_set_y(button_list[i], btn_y);
        lv_obj_set_style_radius(button_list[i], LV_RADIUS_CIRCLE, LV_PART_MAIN | LV_STATE_DEFAULT);
        lv_obj_set_style_bg_opa(button_list[i], 0, LV_PART_MAIN | LV_STATE_DEFAULT);
        lv_obj_set_style_bg_color(button_list[i], lv_color_hex(0xFFFFFF), LV_PART_MAIN | LV_STATE_DEFAULT);
        lv_obj_set_style_border_width(button_list[i], 5, LV_PART_MAIN | LV_STATE_DEFAULT);
        lv_obj_set_style_border_color(button_list[i], lv_color_hex(0x1F1766), LV_PART_MAIN | LV_STATE_DEFAULT);
        lv_obj_set_style_shadow_width(button_list[i], 1, LV_PART_MAIN | LV_STATE_DEFAULT);
        lv_obj_set_style_shadow_color(button_list[i], lv_color_hex(0x1F1766), LV_PART_MAIN | LV_STATE_DEFAULT);

        lv_obj_add_event_cb(button_list[i], button_event_handler, LV_EVENT_ALL, (void *)(intptr_t)i);

        lv_obj_t *id_label = lv_label_create(button_list[i]);
        lv_label_set_text_fmt(id_label, "ID: %d", buttonsData[i].id);
        lv_obj_center(id_label);

        // Name Label - Buton ismini göster
        name_labels[i] = lv_label_create(btn_container);
        lv_label_set_text_fmt(name_labels[i], buttonsData[i].name);
        lv_obj_align_to(name_labels[i], button_list[i], LV_ALIGN_OUT_TOP_MID, 0, -10);
        lv_obj_set_style_text_font(name_labels[i], &lv_font_montserrat_18, LV_PART_MAIN | LV_STATE_DEFAULT);
        lv_obj_set_style_text_color(name_labels[i], lv_color_hex(0xFFFFFF), LV_PART_MAIN | LV_STATE_DEFAULT);
    }
}
