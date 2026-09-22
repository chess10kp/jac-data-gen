# Data Manifest

Updated 2026-09-22. Every dataset in `data/` classified by role. Row counts as of this date.
Regenerators live in `scripts/gen/`; masters are append-only — never hand-edit.

## Release datasets (training-ready)

### A. Translation pipelines — source → idiomatic Jac (deterministic floor + LLM idiomize + guard)

| file | rows | source | task | guard |
|---|---|---|---|---|
| `py2jac_dataset_idiomatic.jsonl` | 9,371 | nuprl/MultiPL-T tested Python (≥90% cov) | Python fn → idiomatic Jac | `jac test` + hidden tests, floor fallback |
| `composer_dataset.jsonl` | 15,144 | same family | same contract, cursor-composer seam | `jac check` |
| `composer_dataset_mut.jsonl` | 804 | composer master | mutation-augmented variant | inherited |
| `js2jac_dataset_idiomatic.jsonl` | 5,195 | GitHub React/TSX repos | JS/TSX project → Jac | `jac check` + ORM/behavioral/hollowness |
| `farm_dataset.jsonl` | 1,731 | GitHub Beanie/ODMantic models | Mongo ODM → node archetype + CRUD walkers | behavioral persistence-delta gate |
| `farm_handler_dataset.jsonl` | 983 | farm master | handler variant | same |

Schema A: `{source, entrypoint, jac, id}` (farm adds `node/archetype/manifest/walkers/gate`).
Pipeline diagrams: `docs/{py2jac,js2jac,farm}_pipeline.mmd`; plan `docs/PLAN.md`.

### B. OSP synthesis (object-spatial programming) — primary active family

| file | rows | what |
|---|---|---|
| `osp_dataset.jsonl` | 7,275 | synthetic OSP code-gen SFT (`messages`); generators: openrouter 4,976 / cursor-cli 1,308 / pi-cli 975 / zai-coding 16 |
| `osp_dataset_pass.jsonl` | 2,228 | strictly test-verified subset (`jac_tests`, `test_verdict=PASS`) |
| `osp_lift_dataset.jsonl` | 567 | lift task: plain-Jac floor → idiomatic OSP (tracks S/1/2/3), seeded from GitHub issues |
| `osp_merged_corpus.jsonl` | 7,842 | merged dedup corpus; tiers: legacy_test_verified 2,196 / legacy_compile_only 5,079 / v21_gold 543 / v21_candidate 24. **`sft_release_set` = 543 (v21_gold)** |
| `osp_merged_corpus_summary.json` | — | corpus build provenance (spec OSP_IDIOMIZE_TASK-v2.1, jac 0.36.1) |
| `osp_examples/group_{A..E}/` | 100 | curated few-shot seeds (audited clean) |
| `osp_minimax_holdouts.jsonl` | — | holdout eval slice |
| `osp_test_results.jsonl` | 43.9 MB | testgen verdicts (verdict=PASS rows feed repairs) |

Lift working area: `osp_lifts/` (issue_gen `.py/.ref.py/.floor.jac/candidate/guard`, assignments, cost ledger, `_gen_failures`).
Task spec: `docs/OSP_IDIOMIZE_TASK.md`.

### C. Repair / repair-trace harvests (zero generation cost)

| path | rows | what |
|---|---|---|
| `osp_repair/code_fix.jsonl` | 1,004 | broken code + real compiler error → gate-verified fix |
| `osp_repair/test_fix.jsonl` | 1,449 | broken tests → test-verified passing tests |
| `osp_repair/trajectory.jsonl` | 745 | full multi-attempt repair sequences |
| `osp_repair/broken_pool.jsonl` | 6,788 | broken code + error, unpaired — Tier-A generation feed |
| `repair_nonosp_fixany_results.jsonl` | 6,129 | model repair of non-OSP masters (composer 5,880 / js2jac 124 / farm 116) |
| `repair_nonosp_failures.jsonl` | 3,375 | same, still-failing tail |

Details: `osp_repair/README.md`. Packer: `scripts/gen/pack_repair_traces.py`.

### D. Human-written Jac corpus (scrape, no LLM in loop)

- `jachacks_all_jac_files_filtered.jsonl` — **1,820 files / 153 repos / 12.2 M chars, training-ready**
- `jachacks_{sf,spring,2026}_jac_files_filtered.jsonl` — per-edition (752/305/763 files)
- `jachacks_all_jac_files.jsonl` + per-edition raw — 17,031 files incl. duplicated jaseci (do not train on)
- `jachacks_{sf,spring,2026}_dataset.jsonl` — repo metadata; `_summary.md` / `_inventory.json`
- `jachacks_{sf,spring,2026}_repos/` — 2.4 GB shallow clones (gitignored)
- `jachacks_scrape/` — Devpost/GitHub link dumps + inventories (scrape inputs, moved from repo root 2026-09-22)
- READMEs: `JACHACKS_ALL_README.md`, `JACHACKS_SF_README.md`

### E. Doc/example-seeded instruction SFT ("golden client")

- `golden_client.jsonl` (9,608) + `golden_client2.jsonl` (826) — seeded from Jac docs (`doc:<section>#<heading>`) and jaseci/jaclang sources; ~30 task types (concept_recall, docstring_authoring, python_to_jac_function, walker_traversal, cl_component_authoring, …); generators fable-api/opus-api/jac-py2jac. Same message schema as osp_dataset. (Moved from repo root 2026-09-22.)
- `golden_client_jac/` — 6,209 extracted `.jac` outputs (`convtier_sftauto_*`); extractor `scripts/eval/extract_golden_jac.py`

## Leads — gate-failure ledgers (inputs to next repair/generation waves; do NOT archive)

Already harvested into `osp_repair/`, but kept hot as append targets and pairing sources:
`osp_testgen_failures.jsonl` (216 MB), `osp_minimax_failures.jsonl` (124 MB),
`osp_{composer,glm,gpt,luna,muse}_failures.jsonl`, `osp_repair_failures.jsonl`,
`osp_repaired.jsonl`, `osp_repair_deferred.jsonl`, `osp_testgen_skip.txt`.

## Inputs (mined/scraped source material, not training data)

- `graph_targets/issues.jsonl` (13,399) + `issues_rescored.jsonl` — GitHub issues mined as task targets for graph-program generation (`scripts/graph_targets/`)
- `samples/python_source_examples.json`, `schema_summary.json` — MultiPL-T source schema notes
- `run_ledger.sqlite3` — generation run ledger

## Audit / QC (derived)

- `audit_nonosp_units.jsonl` (23,153) + `audit_nonosp_report.json` — `jac check` audit of composer/farm/js2jac/osp_examples
- `audit_generated_units.jsonl` + `audit_generated_report.json`, `audit_merged_corpus_postcleanup_units.jsonl` + report

## Evaluation (outside data/)

`../fn_eval_preds/` (grading harness + preds), `../runs/function_eval/`, `../evals/`.

## Archived (cold; moved 2026-09-22, paths updated in scripts)

- `../archive/2026-09/data_logs/` — 39 generation/shard logs from data/ root
- `../archive/2026-09/data_bak/` — 5 master backups (`.bak`, `.bak.<ts>`)
- `../archive/2026-09/scratch/` — dead experiment scratch: `step2..step4f`, `step4_zen_{b,c}`, `chunks`, `farm_chunks`, `floorfix`, `composer_pending`, `composer_dataset.jsonl.d`, `reguard_*`, `py2jac_dogfood`, `jac_outputs`, `farm_handler`, `tmp`, `holepatch_*`, `graph_shaped_scan.jsonl`, `chunk_probe.jsonl`, `osp_B29_*.jac`
- `../archive/2026-08/` — earlier retired drivers; `../archive/2026-09/fn_eval_preds.tar.gz` — packaged snapshot (live dir stays at root)
- Historical drivers/watchers in `scripts/` now point at these archive paths.

## Repo root (non-data, kept in place)

`vendor/jac`, `jaseci/` (compiler checkout — shared LLVM slice, see AGENTS.md), `JacCoder/` (separate CPT/SFT training workspace with its own `dataset/`), `docs/`, `low_resource_paper.pdf`, `fn_eval_preds/`.
