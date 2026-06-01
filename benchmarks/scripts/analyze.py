#!/usr/bin/env python3
"""
Análise da matriz C1–C4 (Pilar 4).

Lê `benchmarks/results/*/metadata.json`, agrega por (cenário × carga),
compara pares C1↔C2 e C3↔C4, e gera:
  - benchmarks/reports/summary.json
  - benchmarks/reports/matriz-resultados.md
  - benchmarks/reports/figures/*.png  (se matplotlib estiver disponível)

Uso:
  python3 analyze.py                 # agrega tudo em results/
  python3 analyze.py --glob '20260601-*'
"""

from __future__ import annotations

import argparse
import json
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / "benchmarks/results"
REPORTS = ROOT / "benchmarks/reports"

PAIRS = [("C1", "C2", "Raspberry Pi — ECDSA vs ML-DSA"),
         ("C3", "C4", "ESP32-D — ECDSA vs ML-DSA")]
METRICS = [
    ("latency_ms_p50", "Latência p50 (ms)"),
    ("latency_ms_p95", "Latência p95 (ms)"),
    ("tps", "TPS"),
    ("avg_payload_bytes", "Payload médio (bytes)"),
    ("cpu_percent_avg", "CPU média (%)"),
    ("mem_used_mb_avg", "RAM usada (MB)"),
    ("success_rate", "Taxa de sucesso"),
]


def load_runs(pattern: str) -> list[dict]:
    runs = []
    for meta_file in sorted(RESULTS.glob(f"{pattern}/metadata.json")):
        try:
            runs.append(json.loads(meta_file.read_text(encoding="utf-8")))
        except json.JSONDecodeError:
            continue
    return runs


def aggregate(runs: list[dict]) -> dict:
    """Agrega métricas por (scenario_id, load_profile) sobre múltiplos runs."""
    groups: dict[tuple[str, str], list[dict]] = {}
    for r in runs:
        key = (r.get("scenario_id", "?"), r.get("load_profile", "?"))
        groups.setdefault(key, []).append(r)

    agg: dict[str, dict] = {}
    for (scen, load), items in groups.items():
        summaries = [i.get("summary", {}) for i in items]
        statuses = [i.get("status", "?") for i in items]
        entry = {
            "scenario_id": scen,
            "load_profile": load,
            "runs": len(items),
            "status": "hardware_pending"
            if all(s == "hardware_pending" for s in statuses)
            else "ok",
            "signing_mode": items[0].get("signing_mode", ""),
            "network": items[0].get("network", ""),
            "device": items[0].get("device", ""),
            "metrics": {},
        }
        for key, _label in METRICS:
            vals = [s.get(key) for s in summaries if s.get(key) is not None]
            if vals:
                entry["metrics"][key] = {
                    "mean": round(statistics.mean(vals), 3),
                    "min": round(min(vals), 3),
                    "max": round(max(vals), 3),
                    "n": len(vals),
                }
        agg[f"{scen}-{load}"] = entry
    return agg


def fmt(v) -> str:
    return "—" if v is None else (f"{v:g}" if isinstance(v, (int, float)) else str(v))


def metric_mean(agg: dict, scen: str, load: str, key: str):
    e = agg.get(f"{scen}-{load}")
    if not e:
        return None
    m = e["metrics"].get(key)
    return m["mean"] if m else None


def pct_delta(base, new) -> str:
    if base in (None, 0) or new is None:
        return "—"
    return f"{((new - base) / base) * 100:+.1f}%"


def write_markdown(agg: dict, runs: list[dict]) -> Path:
    REPORTS.mkdir(parents=True, exist_ok=True)
    loads = sorted({e["load_profile"] for e in agg.values()})
    lines: list[str] = []
    lines.append("# Matriz de resultados — Benchmarks C1–C4\n")
    lines.append(f"> Gerado por `analyze.py` · runs analisados: {len(runs)}\n")
    lines.append("\n## Resumo por cenário × carga\n")
    lines.append("| Cenário | Dispositivo | Rede | Carga | Runs | Status | p50 (ms) | p95 (ms) | TPS | Payload (B) | CPU% | RAM(MB) | Sucesso |")
    lines.append("|---------|-------------|------|-------|------|--------|----------|----------|-----|-------------|------|---------|---------|")
    for key in sorted(agg.keys()):
        e = agg[key]
        m = e["metrics"]
        g = lambda k: fmt(m.get(k, {}).get("mean") if m.get(k) else None)
        lines.append(
            f"| {e['scenario_id']} | {e['device']} | {e['network']} | {e['load_profile']} | "
            f"{e['runs']} | {e['status']} | {g('latency_ms_p50')} | {g('latency_ms_p95')} | "
            f"{g('tps')} | {g('avg_payload_bytes')} | {g('cpu_percent_avg')} | "
            f"{g('mem_used_mb_avg')} | {g('success_rate')} |"
        )

    lines.append("\n## Comparação por par (impacto ML-DSA)\n")
    for base, new, title in PAIRS:
        lines.append(f"\n### {title}\n")
        lines.append("| Carga | Métrica | " + base + " | " + new + " | Δ |")
        lines.append("|-------|---------|------|------|---|")
        for load in loads:
            for mkey, mlabel in METRICS:
                b = metric_mean(agg, base, load, mkey)
                nv = metric_mean(agg, new, load, mkey)
                if b is None and nv is None:
                    continue
                delta = pct_delta(b, nv) if mkey != "success_rate" else "—"
                lines.append(f"| {load} | {mlabel} | {fmt(b)} | {fmt(nv)} | {delta} |")

    lines.append("\n## Hipóteses (verificação automática parcial)\n")
    lines.append(_hypotheses(agg, loads))
    lines.append("\n---\n")
    lines.append("Dados brutos: `benchmarks/results/` (gitignored). "
                 "Cenários ESP32 sem hardware aparecem como `hardware_pending`.\n")

    out = REPORTS / "matriz-resultados.md"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return out


def _hypotheses(agg: dict, loads: list[str]) -> str:
    rows = ["| ID | Hipótese | Evidência (se houver dados) |",
            "|----|----------|------------------------------|"]
    # H1: ML-DSA aumenta p95 no Pi (C1 vs C2)
    for load in loads:
        b = metric_mean(agg, "C1", load, "latency_ms_p95")
        n = metric_mean(agg, "C2", load, "latency_ms_p95")
        if b is not None and n is not None:
            verdict = "suporta" if n > b else "não suporta"
            rows.append(f"| H1 | p95 ML-DSA > ECDSA (Pi, {load}) | {pct_delta(b, n)} → {verdict} |")
    # H3: assinatura ML-DSA > 2x ECDSA (payload aqui é FHIR; assinatura medida na borda)
    rows.append("| H3 | Assinatura ML-DSA > 2× ECDSA | medir na borda (edge submit) — ver C1/C2 signAlg |")
    rows.append("| H4/H5 | ESP32 degrada/ falha mais em PQC | requer hardware ESP32 (C3/C4) |")
    return "\n".join(rows)


def make_charts(agg: dict) -> list[Path]:
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("[analyze] matplotlib ausente — pulando gráficos (pip install matplotlib)")
        return []

    figdir = REPORTS / "figures"
    figdir.mkdir(parents=True, exist_ok=True)
    out: list[Path] = []
    loads = sorted({e["load_profile"] for e in agg.values()})

    for mkey, mlabel in [("latency_ms_p95", "Latência p95 (ms)"), ("tps", "TPS")]:
        scen_ids = ["C1", "C2", "C3", "C4"]
        fig, ax = plt.subplots(figsize=(7, 4))
        width = 0.35
        x = range(len(scen_ids))
        for li, load in enumerate(loads):
            vals = [metric_mean(agg, s, load, mkey) or 0 for s in scen_ids]
            ax.bar([xi + li * width for xi in x], vals, width, label=load)
        ax.set_xticks([xi + width / 2 for xi in x])
        ax.set_xticklabels(scen_ids)
        ax.set_ylabel(mlabel)
        ax.set_title(f"{mlabel} por cenário")
        ax.legend()
        fig.tight_layout()
        p = figdir / f"{mkey}.png"
        fig.savefig(p, dpi=120)
        plt.close(fig)
        out.append(p)
    print(f"[analyze] {len(out)} gráfico(s) em {figdir}")
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description="Análise da matriz C1–C4")
    ap.add_argument("--glob", default="*", help="padrão de run_id em results/")
    ap.add_argument("--no-charts", action="store_true")
    args = ap.parse_args()

    runs = load_runs(args.glob)
    if not runs:
        print(f"[analyze] nenhum run em {RESULTS} (glob={args.glob})")
        return
    agg = aggregate(runs)
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "summary.json").write_text(json.dumps(agg, indent=2), encoding="utf-8")
    md = write_markdown(agg, runs)
    if not args.no_charts:
        make_charts(agg)
    print(f"[analyze] resumo: {REPORTS / 'summary.json'}")
    print(f"[analyze] tabela: {md}")


if __name__ == "__main__":
    main()
