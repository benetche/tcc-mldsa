#pragma once

#include "sdkconfig.h"

#ifdef __has_include
#if __has_include("secrets.h")
#include "secrets.h"
#endif
#endif

#ifndef IOMT_SECRETS_WIFI_SSID
#define IOMT_SECRETS_WIFI_SSID CONFIG_IOMT_WIFI_SSID
#endif
#ifndef IOMT_SECRETS_WIFI_PASSWORD
#define IOMT_SECRETS_WIFI_PASSWORD CONFIG_IOMT_WIFI_PASSWORD
#endif
#ifndef IOMT_SECRETS_MQTT_URI
#define IOMT_SECRETS_MQTT_URI CONFIG_IOMT_MQTT_BROKER_URI
#endif

#define IOMT_DEVICE_ID CONFIG_IOMT_DEVICE_ID
#define IOMT_PUBLISH_INTERVAL_MS CONFIG_IOMT_PUBLISH_INTERVAL_MS
#define IOMT_SIGNING_MODE CONFIG_IOMT_SIGNING_MODE

#if CONFIG_IOMT_SCENARIO_C4
#define IOMT_SCENARIO_ID "C4"
#define IOMT_NETWORK "mldsa"
#define IOMT_SIGN_ALG_TARGET "ML-DSA-65"
#else
#define IOMT_SCENARIO_ID "C3"
#define IOMT_NETWORK "baseline"
#define IOMT_SIGN_ALG_TARGET "ECDSA-P256"
#endif

#define IOMT_MQTT_TOPIC_METRICS "iomt/esp32/%s/metrics"
#define IOMT_MQTT_TOPIC_OBSERVATION "iomt/esp32/%s/observation"
