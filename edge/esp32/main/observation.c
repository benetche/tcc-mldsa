#include "observation.h"

#include "edge_sign.h"
#include "iomt_config.h"

#include "esp_err.h"
#include "esp_log.h"
#include "esp_random.h"
#include "esp_timer.h"
#include "mbedtls/md.h"

#include <stdio.h>
#include <string.h>
#include <time.h>

static const char *TAG = "observation";

void observation_generate(iomt_observation_t *obs)
{
    int64_t ns = esp_timer_get_time();
    snprintf(obs->observation_id, sizeof(obs->observation_id), "esp32-%lld", (long long)ns);

    int hr = 60 + (esp_random() % 40);
    int spo2 = 92 + (esp_random() % 8);
    snprintf(obs->vital_json, sizeof(obs->vital_json),
             "{\"hr\":%d,\"spo2\":%d,\"device\":\"%s\"}", hr, spo2, IOMT_DEVICE_ID);

    unsigned char digest[32];
    mbedtls_md_context_t md;
    const mbedtls_md_info_t *info = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
    mbedtls_md_init(&md);
    mbedtls_md_setup(&md, info, 0);
    mbedtls_md_starts(&md);
    mbedtls_md_update(&md, (const unsigned char *)obs->vital_json, strlen(obs->vital_json));
    mbedtls_md_finish(&md, digest);
    mbedtls_md_free(&md);

    snprintf(obs->payload_hash, sizeof(obs->payload_hash), "sha256:");
    char *hex = obs->payload_hash + strlen("sha256:");
    for (int i = 0; i < 32; i++) {
        sprintf(hex + i * 2, "%02x", digest[i]);
    }
    ESP_LOGD(TAG, "obs=%s hash=%s", obs->observation_id, obs->payload_hash);
}

void observation_recorded_at_rfc3339(char *buf, size_t buflen)
{
    time_t now = 0;
    struct tm tm_utc = {0};
    time(&now);
    if (gmtime_r(&now, &tm_utc) != NULL) {
        strftime(buf, buflen, "%Y-%m-%dT%H:%M:%SZ", &tm_utc);
    } else {
        snprintf(buf, buflen, "1970-01-01T00:00:00Z");
    }
}

int observation_format_mqtt(char *buf, size_t buflen, const iomt_observation_t *obs,
                            const iomt_sign_result_t *sign)
{
    const char *sign_alg = sign->err == ESP_OK ? sign->alg : IOMT_SIGN_ALG_TARGET;
    const char *sig = sign->err == ESP_OK ? sign->signature_b64 : "";
    const char *mode = iomt_effective_signing_mode(sign);
    int sign_ok = (sign->err == ESP_OK && sig[0] != '\0') ? 1 : 0;
    char recorded_at[32];
    observation_recorded_at_rfc3339(recorded_at, sizeof(recorded_at));

    return snprintf(
        buf, buflen,
        "{"
        "\"scenario\":\"%s\","
        "\"network\":\"%s\","
        "\"signing_mode\":\"%s\","
        "\"sign_ok\":%s,"
        "\"observation_id\":\"%s\","
        "\"device_id\":\"%s\","
        "\"payload_hash\":\"%s\","
        "\"recorded_at\":\"%s\","
        "\"signAlg\":\"%s\","
        "\"deviceSignature\":\"%s\","
        "\"vital\":%s"
        "}",
        IOMT_SCENARIO_ID, IOMT_NETWORK, mode, sign_ok ? "true" : "false", obs->observation_id,
        IOMT_DEVICE_ID, obs->payload_hash, recorded_at, sign_alg, sig, obs->vital_json);
}
