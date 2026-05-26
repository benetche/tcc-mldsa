# Scripts de benchmark

## Objetivo

Executar a suíte **C1–C4** × `hospital-low` / `hospital-high` com paridade experimental.

## Script principal (a implementar)

`run_suite.sh`:

```bash
# Suíte completa — robustez do TCC
./run_suite.sh --all

# Cenário único
./run_suite.sh --scenario C3 --load hospital-high

# Dry-run (validar configs)
./run_suite.sh --all --dry-run
```

## Saída esperada

```
benchmarks/results/<timestamp>-C1-hospital-low/
  metadata.json
  metrics.csv
  logs/
```

## Implementação futura

1. Carregar YAML de `benchmarks/scenarios/`
2. Disparar cliente Pi ou ESP32 conforme `device`
3. Agregar latência, TPS, bytes, recursos
4. Falhar o build de CI se faltar cenário no `--all` (opcional)

Ver [cenarios-experimentais.md](../../.cursor/context/cenarios-experimentais.md).
