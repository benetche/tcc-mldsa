#include "edge_sign.h"
#include "iomt_config.h"
#include "mqtt_iomt.h"
#include "observation.h"
#include "telemetry.h"
#include "wifi_manager.h"

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "iomt_main";

void app_main(void)
{
    ESP_LOGI(TAG, "IoMT ESP32 — cenário %s rede %s (%s)", IOMT_SCENARIO_ID, IOMT_NETWORK,
             IOMT_SIGNING_MODE);

    ESP_ERROR_CHECK(wifi_manager_init_and_connect());

    telemetry_init();
    ESP_ERROR_CHECK(mqtt_iomt_start());

    char obs_json[512];
    iomt_observation_t obs;
    iomt_sign_result_t sign;

    while (true) {
        telemetry_tick_loop();

        observation_generate(&obs);
        memset(&sign, 0, sizeof(sign));
        esp_err_t sign_err = iomt_sign_payload(obs.payload_hash, &sign);
        if (sign_err != ESP_OK) {
            ESP_LOGW(TAG, "assinatura: %s", esp_err_to_name(sign_err));
        }

        iomt_telemetry_t telem = telemetry_collect();
        mqtt_iomt_publish_metrics(&telem, &sign);

        int n = observation_format_mqtt(obs_json, sizeof(obs_json), &obs, &sign);
        if (n > 0 && n < (int)sizeof(obs_json)) {
            mqtt_iomt_publish_observation(obs_json);
            ESP_LOGI(TAG, "obs publicada id=%s alg=%s sign_ms=%.1f", obs.observation_id,
                     sign.alg, (float)sign.duration_us / 1000.0f);
        }

        vTaskDelay(pdMS_TO_TICKS(IOMT_PUBLISH_INTERVAL_MS));
    }
}
