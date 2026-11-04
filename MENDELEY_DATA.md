# Mendeley Data (Elsevier) — upload steps

Mendeley Data has no public upload API for individual users, so the deposit goes through the browser. It is the natural choice for an Elsevier journal: the dataset gets a DOI, is CC BY 4.0 by default, and links automatically beside the article on ScienceDirect.

1. Build the bundle on Augie: `bash make_deposit.sh`; copy `$SCRATCH/deposit/data/` to your laptop
   (`scp -r cmankala1@augie.villanova.edu:/work/user/cmankala1/deposit/data ./paper3_data`).
2. Go to https://data.mendeley.com, sign in (Elsevier/Mendeley account), **Create a new dataset**.
3. Title: `Data for: Multi-agent LLM systems in engineering: an evidence-calibrated framework and its pre-registered validation on open models`.
   Contributor: Chaitanya Kumar Mankala, Villanova University (add ORCID). Categories: Artificial Intelligence; Engineering Informatics.
   Description: paste the first paragraph of `README.txt` from the bundle. Licence: CC BY 4.0. Related links: the GitHub repo, and the article once it has a DOI.
4. Upload every file in `paper3_data/` (drag-and-drop; the per-experiment tar.gz files are each well under the 10 GB per-file limit). Keep `README.txt` and `SHA256SUMS.txt` at the top level.
5. Choose **Reserve DOI** (not Publish yet). Copy the DOI (`10.17632/xxxxxxxx.1`) into `main.tex` → Data availability → replace `[DOI to be inserted at submission]` with `Mendeley Data, V1, doi:10.17632/xxxxxxxx.1`, and change "Zenodo" to "Mendeley Data". Recompile.
6. In Editorial Manager, give the same DOI in the "Research data" step. Publish the dataset when the paper is accepted (or earlier if you want the preprint to point at live data; a reserved DOI resolves only after publishing).

Zenodo alternative: `zenodo_upload.py` does the same through the API, with a reserved DOI printed before publishing; prefer it if you want the code release DOI'd too (Zenodo's GitHub integration mints a DOI per tagged release).
