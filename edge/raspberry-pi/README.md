# Raspberry Pi 4 — cliente IoMT (cenário C1)

Dispositivo de borda que submete observações ao chaincode **`iomt`** na rede Fabric **baseline** (ECDSA).

## Cenários

| ID | Rede | Status |
|----|------|--------|
| C1 | Baseline | **Implementado** (este cliente) |
| C2 | ML-DSA | Após Pilar 2 (`fabric/mldsa`) |

## Pré-requisitos no Pi

- Go 1.22+
- Rede Fabric baseline acessível (peer na LAN ou Pi local)
- Credenciais **User1@org1.example.com** do test-network

## Deploy no Pi (sem git)

```bash
cp lab.env.example lab.env    # PI_HOST, PI_USER, senha, LAB_FABRIC_HOST
./scripts/deploy-to-pi.sh     # rsync + smoke C1 via SSH
```

Contexto: [.cursor/context/laboratorio-pi.md](../../.cursor/context/laboratorio-pi.md)

## Configuração manual

1. Subir Fabric no host de lab: `fabric/baseline/scripts/network-up.sh` + `deploy-chaincode.sh`
2. Copiar credenciais ou montar `fabric-samples` no Pi
3. Configurar variáveis (automático a partir do test-network):

```bash
source scripts/export-fabric-env.sh
# Ou: cp config.example.env config.env e editar manualmente
```

## Smoke test C1

```bash
# Requer fabric/baseline rede + chaincode implantados
./scripts/smoke-c1.sh
```

Saída esperada: JSON com `"client": "peer-cli"` e `latency_ms`.

Saída JSON: `observation`, `latency_ms`, `ledger`.

## Métricas

```bash
./scripts/collect_metrics.sh 30 1 /tmp/c1-metrics.csv
```

## Peer remoto (Pi separado do Docker host)

- Abrir porta **7051** no firewall do PC que roda o test-network
- `FABRIC_PEER_ENDPOINT=<IP_DO_PC>:7051`
- Certificados TLS e MSP copiados para o Pi (`/opt/tcc-fabric/`)

## Build

```bash
go build -o bin/submit-observation ./cmd/submit-observation/
```

## ESP32

Cenários C3/C4 usam ESP32 quando disponível — ver `edge/esp32/README.md`.
