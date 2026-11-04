#!/usr/bin/env python3
"""Upload the data bundle to Zenodo and get a DOI.  Usage:
   export ZENODO_TOKEN=...   (zenodo.org > account > Applications > Personal access tokens, scopes deposit:write deposit:actions)
   python3 zenodo_upload.py $SCRATCH/deposit/data            # creates a draft, uploads every file, prints the reserved DOI
   python3 zenodo_upload.py $SCRATCH/deposit/data --publish  # also publishes (irreversible)
Use https://sandbox.zenodo.org with a sandbox token first by setting ZENODO_URL."""
import json, os, sys, requests
base = os.environ.get("ZENODO_URL", "https://zenodo.org"); tok = os.environ["ZENODO_TOKEN"]
folder = sys.argv[1]; publish = "--publish" in sys.argv
H = {"Authorization": f"Bearer {tok}"}
meta = {"metadata": {
    "title": "Data for: Multi-agent LLM systems in engineering: an evidence-calibrated framework and its pre-registered validation on open models",
    "upload_type": "dataset",
    "description": ("Per-call records, archived first versions of repaired experiments, Slurm logs, aggregated tables, the pre-registered "
                    "protocol (SHA-256 prefix 26bd602dd83bcf1e) and the deviation log of an eleven-experiment campaign on Llama-3-8B-Instruct, "
                    "Qwen2.5-7B-Instruct and Mistral-7B-Instruct-v0.3 (vLLM, one A100-40GB, Villanova Augie cluster, Oct-Nov 2026). "
                    "Code: https://github.com/CMankala/llm-mas-ladder"),
    "creators": [{"name": "Mankala, Chaitanya Kumar", "affiliation": "Villanova University"}],
    "license": "cc-by-4.0", "access_right": "open",
    "keywords": ["large language models", "multi-agent systems", "pre-registration", "evaluation", "engineering informatics"],
    "related_identifiers": [{"identifier": "https://github.com/CMankala/llm-mas-ladder", "relation": "isSupplementTo", "resource_type": "software"}],
    "version": "1.0.0"}}
r = requests.post(f"{base}/api/deposit/depositions", params={}, json=meta, headers=H); r.raise_for_status(); dep = r.json()
bucket = dep["links"]["bucket"]; print("draft:", dep["links"]["html"]); print("reserved DOI:", dep["metadata"]["prereserve_doi"]["doi"])
for f in sorted(os.listdir(folder)):
    p = os.path.join(folder, f)
    if not os.path.isfile(p): continue
    with open(p, "rb") as fh:
        u = requests.put(f"{bucket}/{f}", data=fh, headers=H); u.raise_for_status()
    print(f"uploaded {f} ({os.path.getsize(p)/1e6:.1f} MB)")
if publish:
    p = requests.post(f"{base}/api/deposit/depositions/{dep['id']}/actions/publish", headers=H); p.raise_for_status()
    print("published:", p.json()["doi_url"])
else:
    print("Draft only. Check it in the browser, then re-run with --publish, or publish from the Zenodo page.")
