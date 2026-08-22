# Design: Single-View Pipeline Integration

**Status:** draft
**Goal:** one unified control plane that runs, monitors, and repairs every stage of
the Jac fine-tuning data pipeline — replacing ~60 ad-hoc scripts, shell
watchers, and `tail -f` ops with a single web view.

---

## 1. Problem statement

The pipeline works end-to-end but exists as scattered, manually-chained pieces:

| Concern | Today | Files |
|---|---|---|
| Source data | Manual HF download | nuprl/MultiPL-T |
| Test translation | CLI script | `scripts/step2_translate_tests.py` |
| Idiomize | 3+ competing backends, each hand-launched | `cursor_composer_batch.py`, `agent_idiomize_prep.py`, `_idiomize_opencode.py`, `step4_full_loop.py` (`--idiomize` seam) |
| Guard / keep-or-fallback | CLI script per variant | `step3_idiomize.py`, `agent_idiomize_guard.py`, `reguard_floors*.py` |
| Repair loops | One-off rescue scripts | `floorfix*.py/sh`, `repair_pass.py`, `holepatch*`, `composer_guard_recover.py` |
| Mutation | CLI script | `step4_mutation.py` |
| Quality gates | Rubric scoring, denylist | `rubric_score.py`, `apply_function_eval_denylist.py` |
| Eval suites | Build/seal/grade CLIs | `build_function_eval.py`, `seal_function_eval.py`, `eval_jac.py` |
| Cost tracking | SQLite ledger (good!) | `generation_ledger.py` → `data/run_ledger.sqlite3` |
| Record inspection | One static HTML viewer for one dataset | `data/farm_viewer.html` |
| Ops safety | Tribal knowledge | `HOWTO.md` (one-composer-job rule, MCP re-enable after crash, `/tmp` purge, emergency stop) |

Consequences: no global progress picture, duplicate/conflicting runs (the
"kill each other's processes" failure), silent state divergence between master
JSONLs (`data/composer_dataset.jsonl`, `farm_dataset.jsonl`, …), and ops that
only the person who wrote each script can perform.

## 2. Goals

1. **One view** showing pipeline DAG status, live run progress, dataset health,
   costs, and eval results.
2. **Job control** from the same view: start / resume / stop any stage, with the
   single-writer locks from `HOWTO.md` enforced by the system, not memory.
3. **Record-level drill-down**: browse any JSONL master with source/status
   filters (floor vs idiomatic vs failed), view diff py2jac-floor → idiomatic,
   jump to test results.
4. **Ops panel**: disk pressure, stale temp files, MCP/auth status, emergency
   stop, lock ownership.
5. **No rewrite of working logic**: stages stay as-is; the view wraps them.

## 3. Non-goals

- Reimplementing idiomize, guard, dedup, or eval logic inside the server.
- Multi-user auth (localhost tool).
- Changing the on-disk record schema beyond additive fields.

## 4. Architecture

```
┌─────────────────────────── Single Web View ───────────────────────────┐
│  DAG board │ Runs │ Records │ Evals │ Costs │ Ops                     │
└───────────────▲───────────────────────────────────────────────────────┘
                │ HTTP + SSE (live tail)
┌───────────────┴───────────────┐     adapters (subprocess, read-only)
│  pipeline-server (FastAPI)    │◄─── step2/3/4, composer_batch, floorfix…
│  ├─ job queue + lock manager  │
│  ├─ state store (SQLite)      │◄─── generation_ledger.sqlite3 (existing)
│  ├─ artifact scanner          │◄─── data/*.jsonl manifests, logs, chunks
│  └─ ops probes (disk/MCP/pgrep│
└───────────────────────────────┘
```

One process: **`pipeline-server`** (Python/FastAPI, stdlib + fastapi only).
Frontend is one static page (extend the `farm_viewer.html` design language:
dark theme, JetBrains Mono, sidebar + main split).

### 4.1 Stage registry (the DAG)

Stages declared declaratively so new ones are config, not code:

```python
STAGES = [
  Stage(id="source",      kind="manual",    desc="MultiPL-T download"),
  Stage(id="translate",   kind="cli",       cmd="step2_translate_tests.py", inputs=["source"],        out="data/step2/results.json"),
  Stage(id="idiomize",    kind="cli",       cmd="step4_full_loop.py", backends=["mock","opencode","zen","composer"], out="data/<master>.jsonl"),
  Stage(id="guard",       kind="cli",       cmd="agent_idiomize_guard.py", inputs=["idiomize"]),
  Stage(id="repair",      kind="cli",       cmd=["repair_pass.py","floorfix.py","reguard_floors.py"], inputs=["guard"], loop=True),
  Stage(id="mutation",    kind="cli",       cmd="step4_mutation.py", inputs=["repair"]),
  Stage(id="finalize",    kind="builtin",   fn="fmt+rouge-l-dedup", inputs=["mutation"]),
  Stage(id="eval",        kind="cli",       cmd=["build_function_eval.py","seal_function_eval.py","eval_jac.py"], inputs=["finalize"]),
]
```

Each adapter = subprocess wrapper + log capture + exit-code → status mapping +
progress parsing (scripts already emit counters; where they don't, parse the
ledger DB instead).

### 4.2 Job & lock manager

- Jobs are rows in the state store: `{id, stage, backend, args, pid, status,
  started, heartbeat, log_path}`.
- **Resource locks** encode `HOWTO.md` rules: `composer` and `farm` backends
  take an exclusive lock — the UI refuses to start a second job and shows who
  holds it (fixes failure mode #1).
- Heartbeats: orphaned PIDs (crashed driver) are detected and surfaced as
  "needs cleanup" with one-click emergency stop + MCP re-enable
  (`cursor-agent mcp enable browsermcp/jac`) — fixes failure mode #2.
- Resume = re-invoke the same script's existing resume flags
  (`--offset`, checkpoint dirs like `data/reguard_checkpoints/`).

### 4.3 Artifact scanner

A periodic (5s) scan builds the read model — no migration required:

- Masters: line count, source histogram (`floor` / `idiomatic` /
  `failed` / `mutant`), last-modified, delta since last scan.
- Yield ladder per run (from `manifest.json` emitted by `step4_full_loop.py`):
  `seen → py2jac ok → floor pass → kept → fmt → dedup → FINAL`.
- Ledger rollups: tokens/cost by run, backend, day (queries existing
  `run_ledger.sqlite3`, WAL-safe reads only).

### 4.4 State store

New tiny SQLite (`data/pipeline_state.sqlite3`): jobs, locks, events.
Everything else stays derived-from-artifacts so the CLI workflow keeps working
when the server is off.

## 5. The single view (UI)

Six panels, one route, top-level tab strip:

1. **DAG board** — stages as nodes colored by freshness/status; click → runs
   list for that stage; headline metric front-and-center: *idiomatic-kept vs
   fell-back ratio*.
2. **Runs** — active + historical jobs: progress bar (parsed from logs/ledger),
   ETA, cost so far, buttons: stop / resume / open log (live SSE tail).
3. **Records** — the `farm_viewer.html` experience generalized to any master:
   filter by source/status/function-name, side-by-side Python ↔ floor ↔
   idiomatic, guard verdict, rubric score.
4. **Evals** — function & jac-native suite results over time, per-model pass@k.
5. **Costs** — token/call ledger charts by run/backend/model.
6. **Ops** — disk gauge (`/tmp`, `/`), stale `jactmp_*`/`tmp*` purge button,
   lock table, MCP status, auth status, big red **EMERGENCY STOP**
   (pkill sequence from `HOWTO.md` + MCP restore, atomic).

## 6. API sketch

```
GET  /api/dag                     # stage statuses + freshness
POST /api/jobs                    # {stage, backend, args} → job id (409 if locked)
GET  /api/jobs?active=1           # incl. heartbeat, progress, cost
POST /api/jobs/{id}/stop          # SIGTERM→SIGINT→SIGKILL ladder
GET  /api/masters                 # list + histograms
GET  /api/masters/{name}/records?source=floor&limit=50&cursor=…
GET  /api/ledger/summary?by=run|backend|day
GET  /api/logs/{job_id}?tail=200  # SSE stream
GET  /api/ops/health              # disk, locks, mcp, auth, stray procs
POST /api/ops/purge-tmp | /api/ops/emergency-stop
```

## 7. Milestones

| Phase | Deliverable | Effort |
|---|---|---|
| M1 | Read-only: artifact scanner + DAG board + masters browser (reuse farm_viewer CSS) | ~2 days |
| M2 | Job manager: start/stop/resume + exclusive backend locks + SSE logs | ~3 days |
| M3 | Ledger/costs + yield-ladder dashboards; eval panel | ~2 days |
| M4 | Ops panel (disk, MCP, emergency stop); repair-loop one-click actions | ~2 days |

M1 alone delivers most of the visibility value and touches nothing mutable.

## 8. Risks / decisions

1. **Progress parsing is per-script.** Mitigate by preferring ledger-derived
   counts (already durable) over log scraping; add `--progress-json PATH` to
   key scripts where needed (small, additive).
2. **Scripts mutate masters in place** (`jsonl_io.atomic_write`). Scanner must
   snapshot before diffing to avoid torn reads.
3. **Backend drift**: composer/farm/opencode evolve quickly. Keep adapters thin;
   the registry (4.1) is the only place that names them.
4. **Scope creep into orchestration.** v1 does not chain stages automatically —
   it enforces legality and shows state; auto-DAG execution is v2.
