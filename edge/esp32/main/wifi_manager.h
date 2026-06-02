#pragma once

#include "esp_err.h"

/** Inicializa NVS, rede e conecta Wi-Fi (bloqueia até IP ou timeout). */
esp_err_t wifi_manager_init_and_connect(void);

/** RSSI atual (dBm) ou 0 se desconectado. */
int8_t wifi_manager_rssi_dbm(void);
