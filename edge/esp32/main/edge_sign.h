#pragma once

#include <stddef.h>
#include <stdint.h>

#include "esp_err.h"

#define IOMT_SIGN_ALG_MAX 24
#define IOMT_SIGN_B64_MAX 256

typedef struct {
    char alg[IOMT_SIGN_ALG_MAX];
    char signature_b64[IOMT_SIGN_B64_MAX];
    int signature_bytes;
    int64_t duration_us;
    esp_err_t err;
} iomt_sign_result_t;

/** Assina payload_hash conforme cenário (C3 ECDSA / C4 tentativa ML-DSA). */
esp_err_t iomt_sign_payload(const char *payload_hash, iomt_sign_result_t *out);
