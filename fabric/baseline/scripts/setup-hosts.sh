#!/usr/bin/env bash
# Adiciona hostnames do test-network em /etc/hosts (requer sudo).
# Necessário para Fabric Gateway no host resolver peer0.org2.example.com.
set -euo pipefail

LINE="127.0.0.1 peer0.org1.example.com peer0.org2.example.com orderer.example.com"

if grep -q 'peer0.org1.example.com' /etc/hosts 2>/dev/null; then
  echo "OK: entradas Fabric já presentes em /etc/hosts"
  exit 0
fi

echo "Adicionando: ${LINE}"
if sudo -n true 2>/dev/null; then
  echo "${LINE}" | sudo tee -a /etc/hosts >/dev/null
  echo "OK: /etc/hosts atualizado"
else
  echo "Execute manualmente com sudo:" >&2
  echo "  echo '${LINE}' | sudo tee -a /etc/hosts" >&2
  exit 1
fi
