# Dados de saúde — MIMIC-IV / FHIR R4

Ingestão de sinais vitais para o chaincode `iomt` (Pilar 3). Usado pelos benchmarks com paridade baseline/mldsa.

Estado: [docs/estado-do-projeto.md](../docs/estado-do-projeto.md) · MIMIC: [docs/mimic-acesso.md](../docs/mimic-acesso.md).

## Estrutura

| Caminho | Conteúdo |
|---------|----------|
| `mappings/mimic-fhir.md` | Mapeamento MIMIC-IV → FHIR |
| `fixtures/` | Bundles sintéticos (`SYNTHETIC`) para CI |
| `schemas/` | JSON Schema mínimo (validação) |
| `python/iomt_fhir/` | Biblioteca Python (modelos, MIMIC, hash) |

## Scripts de ingestão

```bash
cd scripts/ingestion
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Validar fixtures
python3 validate_fhir.py

# Smoke (5 observações → Fabric)
./run-ingest-smoke.sh baseline

# Carga hospital-low (5 min)
./run-hospital-load.sh hospital-low baseline
```

## Variáveis de ambiente

| Variável | Descrição |
|----------|-----------|
| `MIMIC_DATA_PATH` | Raiz MIMIC-IV local (fora do git) |
| `PHYSIONET_USER` / `PHYSIONET_PASSWORD` | Credenciais PhysioNet |
| `FABRIC_SAMPLES_DIR` | Clone fabric-samples |
| `FABRIC_NETWORK` | `baseline` ou `mldsa` |

Ver [docs/mimic-acesso.md](../docs/mimic-acesso.md).

## Privacidade

- Dados MIMIC brutos em `health-data/mimic/raw/` (gitignored)
- Fixtures rotuladas `dataSource: SYNTHETIC`
- Logs sem PHI (apenas IDs anonimizados)
