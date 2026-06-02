#!/usr/bin/env bash
# Carrega ESP-IDF no shell atual (instalação em ~/esp/esp-idf).
set -euo pipefail
IDF_PATH="${IDF_PATH:-$HOME/esp/esp-idf}"
if [[ ! -f "${IDF_PATH}/export.sh" ]]; then
  echo "ESP-IDF não encontrado em ${IDF_PATH}"
  echo "Clone: git clone -b v5.3.2 --recursive https://github.com/espressif/esp-idf.git ~/esp/esp-idf"
  echo "Instale: cd ~/esp/esp-idf && ./install.sh esp32  (fora de venv Python)"
  exit 1
fi
# shellcheck disable=SC1090
source "${IDF_PATH}/export.sh"
echo "ESP-IDF ativo: $(idf.py --version 2>/dev/null | head -1)"
