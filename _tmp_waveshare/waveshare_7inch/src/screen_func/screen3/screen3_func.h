#ifndef SCREEN3_FUNC_H
#define SCREEN3_FUNC_H

#include "lvgl.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif
typedef struct {
    lv_obj_t *container;
    lv_obj_t *slider;
    lv_obj_t *value_label;
} FuelCell;

#define MAX_CELLS 4
extern FuelCell fuelCell[MAX_CELLS];

extern lv_obj_t *ui_fuelArc;
extern lv_obj_t *ui_fueldeger;
extern lv_obj_t *ui_fuelMiktar;
void create_fuel_cell(FuelCell fuelCell[MAX_CELLS], lv_obj_t *parent, int index, int x_offset, int y_offset, int slider_value, const char *label_text, const char *value_text);
void create_multiple_fuel_cells(lv_obj_t *parent, int adet);
void update_fuel_cell(int index, int slider_value);

#ifdef __cplusplus
}
#endif

#endif // SCREEN3_FUNC_H
