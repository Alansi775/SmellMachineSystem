#ifndef SCREEN1_FUNC_H
#define SCREEN1_FUNC_H

#include "lvgl.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_CELLS_BAT 3
typedef struct {
    lv_obj_t *container;
    lv_obj_t *slider;
    lv_obj_t *value_label;
} BatteryCell;

extern BatteryCell battery_cells[MAX_CELLS_BAT ];

void create_battery_cell(lv_obj_t *parent, int index, int x_offset, int y_offset, int slider_value, const char *label_text, const char *value_text);
void create_multiple_battery_cells(lv_obj_t *parent, int adet);
void update_battery_cell(int index, int slider_value);

#ifdef __cplusplus
}
#endif

#endif // SCREEN1_FUNC_H