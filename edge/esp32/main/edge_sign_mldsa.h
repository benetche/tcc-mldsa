#pragma once

#include "edge_sign.h"

esp_err_t iomt_sign_mldsa_65(const char *payload_hash, iomt_sign_result_t *out);
