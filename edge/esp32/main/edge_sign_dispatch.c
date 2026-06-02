#include "edge_sign.h"
#include "edge_sign_ecdsa.h"
#include "edge_sign_mldsa.h"

#include "esp_timer.h"

esp_err_t iomt_sign_payload(const char *payload_hash, iomt_sign_result_t *out)
{
    int64_t t0 = esp_timer_get_time();
    esp_err_t err;

#if CONFIG_IOMT_SCENARIO_C4
    err = iomt_sign_mldsa_65(payload_hash, out);
#else
    err = iomt_sign_ecdsa_p256(payload_hash, out);
#endif

    out->duration_us = esp_timer_get_time() - t0;
    out->err = err;
    return err;
}
