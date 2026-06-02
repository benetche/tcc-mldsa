#pragma once

#include <stdbool.h>

#include "esp_err.h"

/** Inicializa NVS, rede e conecta Wi-Fi (bloqueia até IP ou timeout). */
esp_err_t wifi_manager_init_and_connect(void);

/** true após SNTP com epoch plausível. */
bool wifi_manager_time_synced(void);

/** RSSI atual (dBm) ou 0 se desconectado. */
int8_t wifi_manager_rssi_dbm(void);
