# Mapeamento MIMIC-IV → HL7 FHIR R4

Referência para ingestão IoMT (Pilar 3). Dados reais **não** são versionados no git.

## Tabelas MIMIC-IV (hosp)

| Tabela MIMIC | Uso no TCC |
|--------------|------------|
| `hosp/patients` | `Patient` (subject) |
| `icu/chartevents` | Sinais vitais → `Observation` |
| `icu/d_items` | Metadados de `itemid` (rótulo, unidade) |

Caminho típico após download: `$MIMIC_DATA_PATH/hosp/patients.csv.gz`, `icu/chartevents.csv.gz`.

## Patient

| MIMIC (`patients`) | FHIR R4 `Patient` |
|--------------------|-------------------|
| `subject_id` | `identifier[0].value` = `mimic-{subject_id}` |
| — | `meta.tag[0].code` = `SYNTHETIC` ou `MIMIC` |
| `gender` | `gender` (m/f → male/female/other) |
| `anchor_age` | extensão / nota em `extension` (opcional) |

## Device (IoMT simulado)

| Campo | Valor |
|-------|--------|
| `Device.id` | `device-pi-{ward}-001` ou `device-esp32-lab` |
| `Device.type` | `coding` SNOMED 706172005 (Vital signs monitor) |
| `Device.patient` | referência `Patient/mimic-{subject_id}` |

## Observation (sinais vitais)

Mapeamento `chartevents.itemid` → LOINC (subset usado no TCC):

| itemid | Sinal | LOINC | Unidade UCUM |
|--------|-------|-------|--------------|
| 220045 | Heart rate | 8867-4 | `/min` |
| 220179 | Non-invasive blood pressure systolic | 8480-6 | `mm[Hg]` |
| 220180 | Non-invasive blood pressure diastolic | 8462-4 | `mm[Hg]` |
| 220210 | Respiratory rate | 9279-1 | `/min` |
| 220277 | O2 saturation pulseoxymetry | 2708-6 | `%` |
| 223761 | Temperature Fahrenheit | 8310-5 | `degF` |
| 223762 | Temperature Celsius | 8310-5 | `Cel` |

| MIMIC (`chartevents`) | FHIR `Observation` |
|-----------------------|-------------------|
| `subject_id` | `subject.reference` → `Patient/mimic-{id}` |
| `charttime` | `effectiveDateTime` (ISO 8601 UTC) |
| `valuenum` | `valueQuantity.value` |
| `valueuom` | `valueQuantity.unit` (normalizado para UCUM) |
| `itemid` | `code.coding[0]` (LOINC conforme tabela) |
| — | `status` = `final` |
| — | `category` = `vital-signs` |
| — | `device.reference` → `Device/...` |

## Payload on-chain (chaincode `iomt`)

A transação Fabric armazena **metadados + hash** do JSON FHIR canônico (não o bundle completo):

| Campo ledger | Origem |
|--------------|--------|
| `patientId` | `mimic-{subject_id}` |
| `loincCode` | LOINC do sinal |
| `valueQuantity` | `{value} {unit}` |
| `payloadHash` | `sha256:` + hex(SHA256(fhir_json)) |
| `fhirPayloadBytes` | tamanho do JSON |
| `dataSource` | `SYNTHETIC` ou `MIMIC` |

Função chaincode: `RegisterFhirObservation`.

## Modo fixture (sem MIMIC)

Gerador sintético: `scripts/ingestion/generate_fixtures.py` — random walk determinístico (seed) para HR/SpO2/BP.
