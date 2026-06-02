#!/usr/bin/env bash
# Wrapper: carrega ESP-IDF e executa idf.py (evita exit 127 no terminal integrado).
set -euo pipefail
ESP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${ESP_ROOT}/scripts/setup-idf-env.sh"
cd "${ESP_ROOT}"
exec idf.py "$@"
