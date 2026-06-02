#include "edge_sign.h"

#include "esp_log.h"
#include "esp_random.h"
#include "mbedtls/base64.h"
#include "mbedtls/ctr_drbg.h"
#include "mbedtls/ecdsa.h"
#include "mbedtls/entropy.h"
#include "mbedtls/pk.h"
#include "nvs.h"
#include "nvs_flash.h"

#include <stdlib.h>
#include <string.h>

static const char *TAG = "edge_sign_ecdsa";
static const char *NVS_NS = "iomt_sign";
static const char *NVS_KEY = "ecdsa_p256";

static esp_err_t load_or_create_key(mbedtls_pk_context *pk)
{
    nvs_handle_t h;
    esp_err_t err = nvs_open(NVS_NS, NVS_READONLY, &h);
    size_t len = 0;
    if (err == ESP_OK) {
        err = nvs_get_blob(h, NVS_KEY, NULL, &len);
        if (err == ESP_OK && len > 0) {
            uint8_t *buf = malloc(len);
            if (!buf) {
                nvs_close(h);
                return ESP_ERR_NO_MEM;
            }
            err = nvs_get_blob(h, NVS_KEY, buf, &len);
            nvs_close(h);
            if (err == ESP_OK) {
                mbedtls_pk_init(pk);
                int ret = mbedtls_pk_parse_key(pk, buf, len, NULL, 0);
                free(buf);
                return ret == 0 ? ESP_OK : ESP_FAIL;
            }
            free(buf);
        } else {
            nvs_close(h);
        }
    }

    mbedtls_pk_init(pk);
    mbedtls_entropy_context entropy;
    mbedtls_ctr_drbg_context ctr;
    mbedtls_entropy_init(&entropy);
    mbedtls_ctr_drbg_init(&ctr);
    const char *pers = "iomt-esp32-ecdsa";
    int ret = mbedtls_ctr_drbg_seed(&ctr, mbedtls_entropy_func, &entropy,
                                    (const unsigned char *)pers, strlen(pers));
    if (ret != 0) {
        mbedtls_ctr_drbg_free(&ctr);
        mbedtls_entropy_free(&entropy);
        return ESP_FAIL;
    }
    ret = mbedtls_pk_setup(pk, mbedtls_pk_info_from_type(MBEDTLS_PK_ECKEY));
    if (ret == 0) {
        ret = mbedtls_ecp_gen_key(MBEDTLS_ECP_DP_SECP256R1, mbedtls_pk_ec(*pk),
                                  mbedtls_ctr_drbg_random, &ctr);
    }
    mbedtls_ctr_drbg_free(&ctr);
    mbedtls_entropy_free(&entropy);
    if (ret != 0) {
        mbedtls_pk_free(pk);
        return ESP_FAIL;
    }

    uint8_t der[512];
    size_t der_len = 0;
    ret = mbedtls_pk_write_key_der(pk, der, sizeof(der));
    if (ret < 0) {
        return ESP_FAIL;
    }
    der_len = (size_t)ret;
    const uint8_t *der_ptr = der + sizeof(der) - der_len;

    err = nvs_open(NVS_NS, NVS_READWRITE, &h);
    if (err != ESP_OK) {
        return err;
    }
    err = nvs_set_blob(h, NVS_KEY, der_ptr, der_len);
    if (err == ESP_OK) {
        err = nvs_commit(h);
    }
    nvs_close(h);
    ESP_LOGI(TAG, "Chave ECDSA-P256 gerada e persistida em NVS");
    return err;
}

esp_err_t iomt_sign_ecdsa_p256(const char *payload_hash, iomt_sign_result_t *out)
{
    mbedtls_pk_context pk;
    esp_err_t err = load_or_create_key(&pk);
    if (err != ESP_OK) {
        return err;
    }

    unsigned char hash[32];
    mbedtls_md_context_t md;
    const mbedtls_md_info_t *info = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
    mbedtls_md_init(&md);
    mbedtls_md_setup(&md, info, 0);
    mbedtls_md_starts(&md);
    mbedtls_md_update(&md, (const unsigned char *)payload_hash, strlen(payload_hash));
    mbedtls_md_finish(&md, hash);
    mbedtls_md_free(&md);

    mbedtls_entropy_context entropy;
    mbedtls_ctr_drbg_context ctr;
    mbedtls_entropy_init(&entropy);
    mbedtls_ctr_drbg_init(&ctr);
  const char *pers_sign = "iomt-ecdsa-sign";
    int ret = mbedtls_ctr_drbg_seed(&ctr, mbedtls_entropy_func, &entropy,
                                    (const unsigned char *)pers_sign, strlen(pers_sign));
    if (ret != 0) {
        mbedtls_pk_free(&pk);
        mbedtls_ctr_drbg_free(&ctr);
        mbedtls_entropy_free(&entropy);
        return ESP_FAIL;
    }

    unsigned char sig_der[128];
    size_t sig_len = 0;
    ret = mbedtls_pk_sign(&pk, MBEDTLS_MD_SHA256, hash, sizeof(hash), sig_der,
                          sizeof(sig_der), &sig_len, mbedtls_ctr_drbg_random, &ctr);
    mbedtls_pk_free(&pk);
    mbedtls_ctr_drbg_free(&ctr);
    mbedtls_entropy_free(&entropy);
    if (ret != 0) {
        ESP_LOGE(TAG, "mbedtls_pk_sign falhou: -0x%04x", -ret);
        return ESP_FAIL;
    }

    size_t olen = 0;
    ret = mbedtls_base64_encode(
        (unsigned char *)out->signature_b64, sizeof(out->signature_b64) - 1,
        &olen, sig_der, sig_len);
    if (ret != 0) {
        return ESP_FAIL;
    }
    out->signature_b64[olen] = '\0';
    strncpy(out->alg, "ECDSA-P256", sizeof(out->alg) - 1);
    out->signature_bytes = (int)sig_len;
    return ESP_OK;
}
