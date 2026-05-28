# Ingestão hospitalar — FHIR → Fabric

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp env.example .env   # editar caminhos
```

## Comandos

```bash
# Gerar fixtures
python3 generate_fixtures.py
python3 validate_fhir.py

# Smoke (3 registros)
./run-ingest-smoke.sh baseline

# Carga hospital-low (5 min, SYNTHETIC)
./run-hospital-load.sh hospital-low baseline

# Carga com MIMIC real
export MIMIC_DATA_PATH=~/data/mimiciv
export IOMT_DATA_SOURCE=MIMIC
./run-hospital-load.sh hospital-low baseline
```

## Payload médio

O resumo JSON ao final inclui `avg_payload_bytes` (JSON FHIR canônico) para benchmarks Pilar 4.
