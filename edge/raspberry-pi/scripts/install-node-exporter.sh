#!/usr/bin/env bash
# Instala node_exporter (arm64) como serviço systemd no Raspberry Pi.
# Expõe métricas de CPU/RAM/disco/rede em :9100 para o Prometheus do lab.
#
# Uso (no Pi):  sudo ./install-node-exporter.sh [versão]
# Depois, no PC: copie monitoring/prometheus/targets/pi.example.json para
#                pi.json com o IP do Pi e recarregue o Prometheus.
set -euo pipefail
VERSION="${1:-1.8.2}"
ARCH="$(uname -m)"
case "${ARCH}" in
  aarch64|arm64) GOARCH="arm64" ;;
  armv7l) GOARCH="armv7" ;;
  x86_64) GOARCH="amd64" ;;
  *) echo "arquitetura não suportada: ${ARCH}" >&2; exit 1 ;;
esac

if [[ "${EUID}" -ne 0 ]]; then
  echo "execute com sudo" >&2
  exit 1
fi

TARBALL="node_exporter-${VERSION}.linux-${GOARCH}.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${TARBALL}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "[node-exporter] baixando ${URL}"
curl -fsSL "${URL}" -o "${TMP}/${TARBALL}"
tar -xzf "${TMP}/${TARBALL}" -C "${TMP}"
install -m 0755 "${TMP}/node_exporter-${VERSION}.linux-${GOARCH}/node_exporter" /usr/local/bin/node_exporter

id -u node_exporter &>/dev/null || useradd --no-create-home --shell /usr/sbin/nologin node_exporter

cat >/etc/systemd/system/node_exporter.service <<'UNIT'
[Unit]
Description=Prometheus Node Exporter (IoMT lab)
After=network-online.target
Wants=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now node_exporter
echo "[node-exporter] ativo em :9100"
ss -ltnp 2>/dev/null | grep ':9100' || true
echo "[node-exporter] valide: curl -s http://localhost:9100/metrics | head"
