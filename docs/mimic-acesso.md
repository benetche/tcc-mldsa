# Acesso ao MIMIC-IV (PhysioNet)

> Credenciais **nunca** no repositório — use variáveis de ambiente ou arquivo local gitignored.

## 1. Credenciamento

1. Criar conta em [PhysioNet](https://physionet.org/)
2. Concluir treinamento CITI (MIMIC-IV)
3. Assinar Data Use Agreement para [MIMIC-IV](https://physionet.org/content/mimiciv/)

## 2. Download

```bash
export PHYSIONET_USER="seu_usuario"
export PHYSIONET_PASSWORD="sua_senha"
export MIMIC_DATA_PATH="$HOME/data/mimiciv/3.1"

mkdir -p "$MIMIC_DATA_PATH"
# wget com credenciais ou ferramenta oficial PhysioNet — ver documentação MIMIC-IV
```

Estrutura esperada pelo ingestor (`health-data/python/iomt_fhir/mimic.py`):

```
$MIMIC_DATA_PATH/
  icu/chartevents.csv.gz   # ou .csv
  hosp/patients.csv.gz
```

## 3. Variáveis de ambiente

```bash
export MIMIC_DATA_PATH=/caminho/local/mimiciv
export PHYSIONET_USER=placeholder
export PHYSIONET_PASSWORD=placeholder
```

Copie `scripts/ingestion/env.example` para `scripts/ingestion/.env` (gitignored).

## 4. Modo desenvolvimento sem MIMIC

Use fixtures sintéticas (padrão):

```bash
export IOMT_DATA_SOURCE=SYNTHETIC
./scripts/ingestion/run-ingest-smoke.sh
```

## 5. Termos e privacidade

- Respeitar [MIMIC-IV license](https://physionet.org/content/mimiciv/view-license//)
- Não publicar dados identificáveis
- IDs no TCC: prefixo `mimic-` ou `synth-` apenas
