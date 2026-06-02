#include "telemetry.h"

#include "wifi_manager.h"

#include "esp_heap_caps.h"
#include "esp_system.h"

static uint32_t s_idle_ticks = 0;
static uint32_t s_loop_ticks = 0;

void telemetry_init(void)
{
    s_idle_ticks = 0;
    s_loop_ticks = 0;
}

void telemetry_tick_loop(void)
{
    s_loop_ticks++;
}

void telemetry_tick_idle(void)
{
    s_idle_ticks++;
}

iomt_telemetry_t telemetry_collect(void)
{
    iomt_telemetry_t t = {0};
    t.heap_free = esp_get_free_heap_size();
    t.heap_min = esp_get_minimum_free_heap_size();
    t.wifi_rssi_dbm = wifi_manager_rssi_dbm();

    uint32_t total = s_idle_ticks + s_loop_ticks;
    if (total > 0) {
        t.cpu_percent = 100.0f * (float)s_loop_ticks / (float)total;
    }

    /* Contadores aproximados — refinados com esp_netif_stats futuramente */
    t.net_tx_bytes = s_loop_ticks * 64;
    t.net_rx_bytes = s_idle_ticks * 64;
    return t;
}
