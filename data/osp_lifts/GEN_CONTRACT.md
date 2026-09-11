# OSP Lift Record Generation Contract (wave batches)

Governing spec: `docs/OSP_IDIOMIZE_TASK.md` v2.1 — §2 semantics, §5 contracts, §6 model task, §8.4 schema.
Pinned walker probe: `scripts/graph_targets/probe_walker_cycle.jac`.

## Per record (one real GitHub issue from YOUR assigned shard)

1. `<issue_gen>/iss_<owner>__<repo>__<issue>.py` — synthetic Python before-code (~40–90 lines;
   70–130 for G2/G3) implementing the hand-rolled machinery the issue describes. Module docstring
   MUST cite `<owner>/<name>#<n>`. Machinery must be genuinely present (pointers / adjacency dicts /
   queue-stack loops / cascade sweeps per the lifts you claim).
2. `.ref.py` — reference harness: imports the module, exercises EVERY public function on a
   deterministic fixture, sorted/multiset-normalizes unspecified order, inline asserts. Exit 0.
3. `.jac` — idiomatic OSP lift. Passes `jac check`.
4. `_guard.jac` — candidate source + appended hidden tests. Passes `jac test`. NOTE: single dot,
   underscore before "guard" — dotted filenames break collection.
5. Floor: `jac tool py2jac <f>.py`; if sanitized output passes `jac check`, save `.floor.jac`,
   floor_status "generated"; else "port_failed". NEVER claim generated without the file.

## Hard rules (review-verified failure modes — do not reintroduce)

- CYCLES: jac has NO built-in visit dedup. Revisits use a claim-map + `skip;` — NEVER
  `disengage` on revisit (it kills the whole walker and truncates closures). Dead ends:
  `visit [...] else { disengage; }`.
- NO def-body docstrings (`Expected 'else'` parse error) — use `#` comments inside defs.
  Module-level docstrings are fine.
- NO `pass;` statement — it does not exist.
- NO module-level mutable state (`glob` registries/dicts/lists) — state lives on an obj handle
  built fresh per test (§5.2). Constant globs are fine.
- ELIMINATION: zero surviving scaffolding anywhere (adjacency dicts of lists, deque/queue/stack
  loops, self-recursive helpers, visited-set plumbing) outside exempt cycle-policy guards.
- FAÇADE FIDELITY (§5.1): public function names/signatures/return SHAPES/exception types/
  unknown-id tolerance match the Python source EXACTLY. The source is ground truth; guards pin
  source semantics, never the candidate's drift.
- MUTATION (§5.5): collect walk (once-only claim-map) → apply disconnects/deletes OUTSIDE any walk.
- TESTS: sorted/multiset where order unspecified; adversarial-order diamond cases for every
  closure/cascade walker (edge insertion such that revisit fires before deeper first-visits);
  negative cases only when the source defines them.
- Connections need definite node instances — narrow optionals before `+>:E:+>`.
- Each record dir chain already has jac.toml `[build] default_codespace = "server"`. If you ever
  see "runtime bring-up failed", retry after a minute (cache re-extract), do not debug it.

## Validation loop (per record, from data/osp_lifts/)

python3 issue_gen/<f>.ref.py -> exit 0;  jac check issue_gen/<f>.jac -> ok;
jac test issue_gen/<f>_guard.jac -> all pass. Fix until green.

## Manifest

Append one JSON line per record to YOUR batch manifest (data/osp_lifts/<manifest>.jsonl):
{"id":"osp__<owner>__<repo>__<issue>__<slug8>","track":"S","category_lifts":["C1"/"C2"/"C5"...],
 "provenance":{"repo":"owner/name","issue":N,"url":"..."},"source_file":"issue_gen/<f>.py",
 "candidate_file":"issue_gen/<f>.jac","guard_file":"issue_gen/<f>_guard.jac",
 "floor_file":null,"floor_status":"generated|port_failed","signals":[...],
 "g_tier":1|2|3,"python_ref_pass":true,"jac_check":true,"jac_test_guard":true}
