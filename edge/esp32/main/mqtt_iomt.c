#include "mqtt_iomt.h"

#include "iomt_config.h"

#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "mqtt_client.h"

#include <stdio.h>
#include <string.h>

static const char *TAG = "mqtt_iomt";
static esp_mqtt_client_handle_t s_client;
static char s_topic_metrics[64];
static char s_topic_observation[64];

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id,
                               void *event_data)
{
    (void)handler_args;
    (void)base;
    esp_mqtt_event_handle_t event = event_data;
    switch ((esp_mqtt_event_id_t)event_id) {
    case MQTT_EVENT_CONNECTED:
        ESP_LOGI(TAG, "MQTT conectado");
        break;
    case MQTT_EVENT_DISCONNECTED:
        ESP_LOGW(TAG, "MQTT desconectado");
        break;
    default:
        break;
    }
}

esp_err_t mqtt_iomt_start(void)
{
    snprintf(s_topic_metrics, sizeof(s_topic_metrics), IOMT_MQTT_TOPIC_METRICS, IOMT_DEVICE_ID);
    snprintf(s_topic_observation, sizeof(s_topic_observation), IOMT_MQTT_TOPIC_OBSERVATION,
             IOMT_DEVICE_ID);

    esp_mqtt_client_config_t cfg = {
        .broker.address.uri = IOMT_SECRETS_MQTT_URI,
    };
    s_client = esp_mqtt_client_init(&cfg);
    if (!s_client) {
        return ESP_FAIL;
    }
    esp_mqtt_client_register_event(s_client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_err_t err = esp_mqtt_client_start(s_client);
    if (err != ESP_OK) {
        return err;
    }
    vTaskDelay(pdMS_TO_TICKS(1500));
    return ESP_OK;
}

esp_err_t mqtt_iomt_publish_metrics(const iomt_telemetry_t *t, const iomt_sign_result_t *sign)
{
    if (!s_client) {
        return ESP_ERR_INVALID_STATE;
    }
    const char *sign_alg = (sign->err == ESP_OK) ? sign->alg : IOMT_SIGN_ALG_TARGET;
    float sign_ms = (float)sign->duration_us / 1000.0f;

    char payload[384];
    int n = snprintf(
        payload, sizeof(payload),
        "{"
        "\"device_id\":\"%s\","
        "\"ts\":%lld,"
        "\"heap_free\":%lu,"
        "\"heap_min\":%lu,"
        "\"cpu_percent\":%.1f,"
        "\"wifi_rssi_dbm\":%d,"
        "\"net_tx_bytes\":%lu,"
        "\"net_rx_bytes\":%lu,"
        "\"sign_alg\":\"%s\","
        "\"sign_duration_ms\":%.1f,"
        "\"scenario\":\"%s\","
        "\"signing_mode\":\"%s\""
        "}",
        IOMT_DEVICE_ID, (long long)(esp_timer_get_time() / 1000000), (unsigned long)t->heap_free,
        (unsigned long)t->heap_min, t->cpu_percent, (int)t->wifi_rssi_dbm,
        (unsigned long)t->net_tx_bytes, (unsigned long)t->net_rx_bytes, sign_alg, sign_ms,
        IOMT_SCENARIO_ID, IOMT_SIGNING_MODE);
    if (n <= 0 || n >= (int)sizeof(payload)) {
        return ESP_ERR_NO_MEM;
    }
    int msg_id = esp_mqtt_client_publish(s_client, s_topic_metrics, payload, 0, 0, 0);
    return msg_id >= 0 ? ESP_OK : ESP_FAIL;
}

esp_err_t mqtt_iomt_publish_observation(const char *json_observation)
{
    if (!s_client) {
        return ESP_ERR_INVALID_STATE;
    }
    int msg_id =
        esp_mqtt_client_publish(s_client, s_topic_observation, json_observation, 0, 1, 0);
    return msg_id >= 0 ? ESP_OK : ESP_FAIL;
}
