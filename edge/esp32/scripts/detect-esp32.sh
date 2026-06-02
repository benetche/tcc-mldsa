#!/usr/bin/env bash
# Detecta porta serial do ESP32 (CH340/CP210x) no Linux.
set -euo pipefail

found=0
for dev in /dev/ttyUSB* /dev/ttyACM*; do
  [[ -e "${dev}" ]] || continue
  echo "porta: ${dev}"
  if [[ -r "${dev}" ]]; then
    echo "  permissão: ok (leitura)"
  else
    echo "  permissão: negada — adicione o usuário ao grupo dialout:"
    echo "    sudo usermod -aG dialout \$USER  # logout/login"
  fi
  found=1
done

if [[ "${found}" -eq 0 ]]; then
  echo "Nenhuma porta ttyUSB/ttyACM encontrada."
  exit 1
fi

if command -v lsusb >/dev/null 2>&1; then
  echo "--- lsusb (serial) ---"
  lsusb | grep -iE '1a86:7523|10c4:|0403:|espressif' || true
fi

exit 0
