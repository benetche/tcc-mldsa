#pragma once

#include "edge_sign.h"

#include <stddef.h>

typedef struct {
    char observation_id[48];
    char payload_hash[80];
    char vital_json[192];
} iomt_observation_t;

/** Gera observação sintética (sinais vitais) e payload_hash sha256:hex. */
void observation_generate(iomt_observation_t *obs);

/** JSON para tópico MQTT observation (inclui assinatura se ok). */
int observation_format_mqtt(char *buf, size_t buflen, const iomt_observation_t *obs,
                            const iomt_sign_result_t *sign);
