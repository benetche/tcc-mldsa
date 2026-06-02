#include "edge_sign.h"

#include "esp_log.h"

#include <string.h>

static const char *TAG = "edge_sign_mldsa";

/**
 * C4 — ML-DSA-65 on-device.
 * Integração liboqs no ESP32 é fase futura (RAM/flash). Retorno documentável para benchmarks.
 */
esp_err_t iomt_sign_mldsa_65(const char *payload_hash, iomt_sign_result_t *out)
{
    (void)payload_hash;
    strncpy(out->alg, "ML-DSA-65", sizeof(out->alg) - 1);
    out->signature_b64[0] = '\0';
    out->signature_bytes = 0;
    out->err = ESP_ERR_NOT_SUPPORTED;
    ESP_LOGW(TAG, "ML-DSA on-device não implementado (use esp32_payload_only / gateway)");
    return ESP_ERR_NOT_SUPPORTED;
}
