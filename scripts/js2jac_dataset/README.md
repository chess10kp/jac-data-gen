# js2jac dataset tooling

Deterministic + LLM-assisted pipelines turning JS/TSX and Mongo-app sources
into idiomatic Jac training data. Large artifacts live in this data repo; the
converter itself lives in `jaseci/jac/jaclang/compiler/js2jac/`.

## Entrypoints (only three — everything else is stage code)

| Entry | Purpose |
|---|---|
| `./js2jac.sh [grind\|chunk] …` | **Corpus grind**: real React/TSX repos → cleaned idiomatic Jac (`js2jac_dataset.jsonl`). Resume-safe; re-run freely. |
| `./farm.sh [full\|grind\|to\|handler] …` | **FARM burndown**: Mongo/Beanie app models → CRUD graph walkers, behaviorally gated (`data/farm_dataset.jsonl`, handler variant separate). |
| `./pilot.py [generate\|validate]` | **Pilot A benchmark corpus**: 100 deterministic fixtures; byte-stable regenerate + `jac check` validation. |

Each script's header comment documents its subcommands. Internal stages are
not meant to be invoked by hand, but can be found under `pipeline/`, `farm/`,
`gates/`, `converters/`, `tools/`, `pilot/`.

## Layout

```
js2jac.sh farm.sh pilot.py     entrypoints
pipeline/                      js2jac stages: prep.py composer.py repair.py chunk.sh grind.sh
farm/                          FARM stages: discover/prep/composer/guard/chunk/grind/full_run…
gates/                         behavioral_gate, orm_behavioral_gate, fidelity_gate
converters/                    prisma_to_jac, mongo_odm_to_jac (deterministic schema lifters)
tools/                         gen_grounding.sh (refresh jac_grounding.md + jac_skills/),
                               upgrade_records.py (backfill floor_mode)
pilot/                         generate_pilot.py, validate.py (+ schema.json, manifest at root)
config/                        strip_policy.json (composer cleanup policy)
docs/                          converter hardening plan, persistence mappings
source/                        harvested candidate sources (input data)
runs/                          per-chunk artifacts: work/, batches/, candidates, dpo_pairs
oracle/                        differential oracle harness (execution-locked cross-language tests)
```

Data masters at the root: `js2jac_dataset.jsonl` (+ `_idiom` variant),
`farm_models.jsonl`, `farm_apps.jsonl`, `pilot_manifest.json`, `schema.json`.

## Resilience standard (shared with the py2jac pipeline)

The composer drivers run on `scripts/lib/composer_harness.py`:

- every model call ledgered durably to `data/run_ledger.sqlite3`
  (inspect: `python3 scripts/lib/generation_ledger.py summary <run_id>`)
- fsync'd lock-protected JSONL appends; corrupt tails quarantine to `<file>.bad`
- transient failures retried with backoff (`--max-attempts`); >50% empty
  batches exit rc=4 so grinders stop early
- resume by record id; partially-done batch files shrink atomically

## Quality gates

- guard stage: the pinned checkout's jac (`.venv/bin/python -m jaclang`) checks
  each candidate under a 3GB prlimit cap; floor-fallback means a bad
  idiomization never destroys a valid record. ORM records additionally pass the
  behavioral gate / hollowness check. The converter/checker also need Bun;
  set `JAC_BUN` when it is not `/usr/sbin/bun`.
- repair pass (step 6): check-failed candidates get a model-assisted fix using
  the compiler error; survivors append as `source=js2jac_repair`.
  Disable with `JS2JAC_REPAIR=0`.
- DPO preference pairs land in `runs/<TAG>/dpo_pairs.jsonl` from four places:
  guard floor-fallbacks (chosen=floor), repair rescues (chosen=repaired),
  hollow-ORM rejections (chosen=floor; both sides compile — equal-correctness
  graph-fidelity pairs), and `pipeline/dpo_backfill.py`, which re-derives
  check-fail/hollow-orm/idiom pairs from existing run artifacts (no generation).

The pipeline does not pip-install Jac. It runs the checked-out js2jac branch
with `/home/jac/repos/jac_llm_data/.venv/bin/python -m jaclang` from
`jaseci/jac`; this avoids the incompatible ambient Jac binary. The source checkout requires Bun, normally `/usr/sbin/bun`, and its native
LLVM shim. Build the shim once from `jaseci/jac`:

```bash
zig build fetch-llvm
zig build jacllvm
```

## Pilot A corpus

Sources: `jaseci/jac/tests/compiler/js2jac/pilot/pilot_*.tsx`; Jac test:
`jaseci/jac/tests/compiler/js2jac/test_pilot_corpus.jac`. Regenerate:

```bash
./pilot.py generate
./pilot.py validate
```

`generate_pilot.py` is deterministic (`PILOT_SEED=20260810`). Known limitations
are listed in `docs/CONVERTER_HARDENING_PLAN.md`.

## Families (100 total)

| Family | Count | Exercises |
|---|---:|---|
| basic_props | 8 | inline props, primitives |
| destructure | 8 | destructuring, external alias |
| jsx_attrs | 7 | static/dynamic attributes |
| jsx_conditionals | 7 | ternary, `&&`, `\|\|` |
| jsx_lists | 7 | `.map` comprehensions |
| hooks_state | 7 | `useState` |
| hooks_effect | 6 | `useEffect` deps |
| hooks_ref | 5 | `useRef` |
| helpers | 7 | local `def` / arrow helpers |
| control_flow | 7 | `if`, `for-of`, `while` |
| ts_types | 7 | unions, generics, interface |
| interop | 6 | `useMemo`, `useCallback`, npm |
| wrappers | 5 | `FC`, `memo`, `forwardRef` |
| native_idioms | 5 | V2.8 list/dict lowering |
| minimal_tsx | 5 | arrow-export JS-style patterns |
| ts_only | 3 | type-alias props |
