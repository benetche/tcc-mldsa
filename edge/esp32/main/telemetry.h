#pragma once

#include <stdint.h>

typedef struct {
    uint32_t heap_free;
    uint32_t heap_min;
    float cpu_percent;
    int8_t wifi_rssi_dbm;
    uint32_t net_tx_bytes;
    uint32_t net_rx_bytes;
} iomt_telemetry_t;

void telemetry_init(void);
void telemetry_tick_loop(void);
iomt_telemetry_t telemetry_collect(void);
