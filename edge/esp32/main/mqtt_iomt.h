#pragma once

#include "edge_sign.h"
#include "telemetry.h"

#include "esp_err.h"

esp_err_t mqtt_iomt_start(void);
esp_err_t mqtt_iomt_publish_metrics(const iomt_telemetry_t *t, const iomt_sign_result_t *sign);
esp_err_t mqtt_iomt_publish_observation(const char *json_observation);
