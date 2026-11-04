#!/bin/bash
# Publish the code repository to GitHub. Run on Augie (needs git; `gh` optional) or copy $SCRATCH/deposit/llm-mas-ladder to your laptop first.
#   1. Create an empty PUBLIC repo named llm-mas-ladder at https://github.com/new (no README, no licence), OR let gh do it (step B).
#   2. bash github_push.sh
set -euo pipefail
source ~/.augie_env 2>/dev/null || true
REPO=${REPO:-$SCRATCH/deposit/llm-mas-ladder}; USER=${GITHUB_USER:-CMankala}
cd "$REPO"
git init -q 2>/dev/null || true
git add -A
git -c user.name="Chaitanya Kumar Mankala" -c user.email="ck.mankala@gmail.com" commit -qm "Harness, protocol and aggregated results for the Paper 3 campaign (v1.0.0)" || true
git branch -M main
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then         # B: gh creates the repo and pushes
  gh repo create "$USER/llm-mas-ladder" --public --source=. --remote=origin --push \
     --description "Harness, pre-registered protocol and results: multi-agent LLM designs tested on open models"
else                                                                          # A: repo already created in the browser
  git remote add origin "https://github.com/$USER/llm-mas-ladder.git" 2>/dev/null || true
  git push -u origin main      # prompts for username + a personal access token (Settings > Developer settings > Tokens, scope: repo)
fi
git tag -a v1.0.0 -m "Version cited in the paper" && git push origin v1.0.0
echo "Done: https://github.com/$USER/llm-mas-ladder  (tag v1.0.0). Optional: on Zenodo, enable the repo under 'GitHub' to get a DOI for the code release."
