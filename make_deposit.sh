#!/bin/bash
# Builds the public deposit for Paper 3 on Augie: a code repository (for GitHub) and a data bundle (for Mendeley Data / Zenodo).
# Run on the Augie login node:  bash make_deposit.sh         Output: $SCRATCH/deposit/
set -euo pipefail
source ~/.augie_env
OUT=$SCRATCH/deposit; CODE=$OUT/llm-mas-ladder; DATA=$OUT/data
rm -rf "$OUT"; mkdir -p "$CODE" "$DATA"
R=$SCRATCH/augie_results

# ---------------------------------------------------------------- 1. code repository (GitHub)
rsync -a --exclude '__pycache__' --exclude '.pytest_cache' --exclude 'results_local' --exclude '*.pyc' \
      "$AUGIE_HARNESS/" "$CODE/harness/"
[ -d "$(dirname "$AUGIE_HARNESS")/llmmas" ] && rsync -a --exclude '__pycache__' "$(dirname "$AUGIE_HARNESS")/llmmas/" "$CODE/llmmas/" || true
mkdir -p "$CODE/protocol" "$CODE/paper_tables"
for f in PROTOCOL_AUGIE_VALIDATION.md DEVIATION_LOG_2026-11-02.md DEVIATION_LOG_ADDENDUM_E3_2026-11-03.md RESULTS_FINAL_2026-11-04.md; do
  [ -f "$SCRATCH/docs/$f" ] && cp "$SCRATCH/docs/$f" "$CODE/protocol/" || echo "NOTE: put $f into $CODE/protocol/ by hand (scp from your laptop)"
done
# aggregated tables and figure data: small, belong with the code so figures regenerate without the full records
for e in $(ls -d "$R"/*/ | xargs -n1 basename); do
  mkdir -p "$CODE/paper_tables/$e"
  for f in table.csv table.tex figure_data.json; do [ -f "$R/$e/$f" ] && cp "$R/$e/$f" "$CODE/paper_tables/$e/"; done
done
cp "$R/preregistration_report.json" "$R/DECISION.txt" "$R"/PHASE*_DEVIATIONS.txt "$CODE/paper_tables/" 2>/dev/null || true
sha256sum "$CODE/protocol/PROTOCOL_AUGIE_VALIDATION.md" 2>/dev/null | cut -c1-16 > "$CODE/protocol/PROTOCOL_HASH.txt" || true
cat > "$CODE/LICENSE" <<'L'
MIT License

Copyright (c) 2026 Chaitanya Kumar Mankala

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
L
cat > "$CODE/CITATION.cff" <<'C'
cff-version: 1.2.0
message: "If you use this code or data, please cite the paper and the deposit."
title: "llm-mas-ladder: harness and records for 'Multi-agent LLM systems in engineering: an evidence-calibrated framework and its pre-registered validation on open models'"
authors:
  - family-names: Mankala
    given-names: Chaitanya Kumar
    affiliation: Villanova University
version: 1.0.0
date-released: 2026-11-04
license: MIT
repository-code: https://github.com/CMankala/llm-mas-ladder
C
cat > "$CODE/README.md" <<'M'
# llm-mas-ladder

Experiment harness, pre-registered protocol and aggregated results for
**"Multi-agent LLM systems in engineering: an evidence-calibrated framework and its pre-registered validation on open models"**
(C. K. Mankala, 2026, submitted to *Advanced Engineering Informatics*).

| Folder | Contents |
|---|---|
| `harness/` | `augie_harness` Python package (experiments E1–E7, R1–R4; 257 tests: `pytest -q`), Slurm scripts (`scripts/campaign.sh`, `phase2–5.sh`), config |
| `llmmas/` | accounting models and analysis helpers the harness builds on |
| `protocol/` | the pre-registered protocol (SHA-256 prefix `26bd602dd83bcf1e`, in `PROTOCOL_HASH.txt`), the deviation log (D1–D20), the final results note |
| `paper_tables/` | per-experiment `table.csv`, `table.tex`, `figure_data.json`; `preregistration_report.json`; gate and archive notes |

The per-call records (JSONL, ~1 GB), the archived first versions of the repaired experiments and the Slurm logs are in the companion data deposit: **[DOI to be inserted]** (Mendeley Data).

## Reproduce a figure
```bash
pip install -e harness
python -m augie_harness.aggregate paper_tables      # rewrites table.csv / figure_data.json from records if present
```
## Reproduce the campaign
Needs one A100-40GB with vLLM 0.31, Llama-3-8B-Instruct, Qwen2.5-7B-Instruct and Mistral-7B-Instruct-v0.3 weights, and Slurm.
See `harness/README.md` and `protocol/`. Set `~/.augie_env` (SCRATCH, AUGIE_HARNESS, AUGIE_VENV, LLAMA8B_PATH) and run `bash scripts/submit_campaign.sh`.

Models: Llama 3 (Meta Llama 3 Community License), Qwen2.5 (Apache-2.0), Mistral 7B (Apache-2.0). Benchmarks: Spider (CC BY-SA 4.0), GSM8K (MIT), 20 Newsgroups. None are redistributed here.
M

# ---------------------------------------------------------------- 2. data bundle (Mendeley Data / Zenodo)
# records per experiment, each as one tar.gz (repositories prefer a handful of files to thousands)
for e in $(ls -d "$R"/*/ | xargs -n1 basename); do
  n=$(find "$R/$e" -name 'seed*.jsonl' | wc -l); [ "$n" -gt 0 ] || continue
  tar czf "$DATA/records_${e}.tar.gz" -C "$R" $(cd "$R" && find "$e" -name 'seed*.jsonl' | sort)
done
tar czf "$DATA/archive_superseded_runs.tar.gz" -C "$SCRATCH" archive
tar czf "$DATA/logs.tar.gz" -C "$SCRATCH" logs/campaign_*.out $(cd "$SCRATCH" && ls augie_results/campaign_*.log | sed 's#^#./#')
cp -r "$CODE/paper_tables" "$DATA/aggregated_tables"; tar czf "$DATA/aggregated_tables.tar.gz" -C "$DATA" aggregated_tables; rm -rf "$DATA/aggregated_tables"
cp "$CODE/protocol/"* "$DATA/" 2>/dev/null || true
cat > "$DATA/README.txt" <<'T'
Data deposit for: Mankala, C. K. (2026). Multi-agent LLM systems in engineering: an evidence-calibrated framework and its pre-registered validation on open models. Submitted to Advanced Engineering Informatics.
Code: https://github.com/CMankala/llm-mas-ladder

records_<experiment>.tar.gz   one JSONL per seed; one line per model call: experiment, config_name (arm), item_id, seed, model, snapshot hash,
                              prompt_digest, tokens_in/out, latency_s, output (first 2,000 chars), checks (outcome fields), protocol_hash, Slurm job, node, timestamp
archive_superseded_runs.tar.gz  the first versions of E2, R3, E3, E4, E5 that were repaired (see the deviation log); nothing was deleted
logs.tar.gz                   campaign and job logs (gates, archive events, timings)
aggregated_tables.tar.gz      table.csv / table.tex / figure_data.json per experiment; preregistration_report.json; PHASE*_DEVIATIONS.txt
PROTOCOL_AUGIE_VALIDATION.md  the pre-registered protocol (SHA-256 prefix 26bd602dd83bcf1e); DEVIATION_LOG_*.md; RESULTS_FINAL_*.md
Licence: CC BY 4.0. Models and benchmarks are not redistributed; see the code repository README.
T
( cd "$DATA" && sha256sum * > SHA256SUMS.txt )
echo; echo "code repo:   $CODE"; echo "data bundle: $DATA"; du -sh "$CODE" "$DATA"; ls -la "$DATA"
