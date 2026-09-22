# jac_llm_data — Jac training-data factory

Datasets, generation pipelines, and eval harnesses for training code models on Jac.

**Start here: [`data/MANIFEST.md`](data/MANIFEST.md)** — the index of every dataset,
led by role (release sets, leads, inputs, audits), with row counts and generators.
Verify it against disk: `python3 scripts/ops/manifest_check.py`.

## Map

| path | what |
|---|---|
| `data/` | **All training data.** Release datasets, failure ledgers, mined inputs, run ledger (`run_ledger.sqlite3`). Indexed by `data/MANIFEST.md`; regenerators in `scripts/gen/`. |
| `scripts/` | Pipeline code: `gen/` (dataset generation), `ops/` (repair waves, guard fixups), `eval/`, `lib/`, `graph_targets/`, and `js2jac_dataset/` (own README + its own data masters). |
| `runs/` | Wave/repair/lift logs, driver scripts (`wave_*.sh`), guard-failure pickles, `function_eval/<model>/` outputs. Regenerable run artifacts — not data. |
| `fn_eval_preds/` | Function eval harness: preds, graded outputs, reports (`GRADING_REPORT.md`), pinned `bin/jac-0.36.1`. Own README. |
| `evals/` | Eval sets: `function/v1` (public/private dev+test, clusters, denylists), `jac_native/v0`. |
| `JacCoder/` | Separate CPT/SFT training workspace with its own `dataset/` — see its README. |
| `docs/` | Task specs (`OSP_IDIOMIZE_TASK.md`), pipeline diagrams (`*_pipeline.mmd`), reports, one-pagers. |
| `archive/` | Cold data and retired drivers by month (`2026-08/`, `2026-09/`); heavy subdirs gitignored. |
| `vendor/jac`, `jaseci/` | Compiler checkouts — see `AGENTS.md` for the shared LLVM slice rule. |

## Where do I find…

- **Training-ready datasets** → `data/MANIFEST.md` §Release datasets (A–E)
- **Failure ledgers for the next repair/generation wave** → `data/MANIFEST.md` §Leads (kept hot, do not archive)
- **Eval results** → `fn_eval_preds/GRADING_REPORT.md`, `runs/function_eval/`, `evals/`
- **What a generation run did** → its log in `runs/` + the ledger: `python3 scripts/lib/generation_ledger.py summary <run_id>` over `data/run_ledger.sqlite3`
- **Something old** → `archive/YYYY-MM/` (layout documented at the end of `data/MANIFEST.md`)

## Conventions

- Dataset masters are **append-only** — never hand-edit; generators live in `scripts/gen/`.
- **`jac` subprocesses on generated/scratch code must pass a sandbox `cwd`** — jac and the code it runs write `.pytest_cache/`, `.jac/`, `save_file()` outputs and bytecode dumps into CWD. The root `conftest.py` sandboxes ad-hoc `jac test` from the repo root and sweeps known droppings after each root-level run; `scripts/ops/check_jac_cwd.py` statically fails any jac spawn without a pinned cwd (enforced as `test_jac_spawn_hygiene` in the pytest suite).
- Scratch/junk is gitignored and cold-archived to `archive/2026-09/root_scratch/` — keep the repo root to real directories + README/AGENTS only.
- Large blobs (raw scrapes, repo clones, logs, archives) stay on disk but out of git; the manifest records them regardless.
