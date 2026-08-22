#!/usr/bin/env bash
# One end-to-end js2jac cleanup chunk: prep -> pack -> composer -> guard -> append.
# Analog of scripts/composer_chunk.sh (py2jac). Difference: the guard gate is
# `jac check` passing (js2jac has no unit tests), which is weaker than py2jac's
# test suite — so REJECT in strip_policy.json carries more weight here.
#
# Usage: js2jac_chunk.sh <offset> <limit> [--faithful]
set -euo pipefail
cd "$(dirname "$0")"                      # scripts/js2jac_dataset
OFFSET="${1:?offset}"; LIMIT="${2:-40}"; FAITHFUL="${3:-}"
TAG="js2jac_${OFFSET}"
WORK="runs/${TAG}/work"
BATCH="runs/${TAG}/batches"
CAND="runs/${TAG}/candidates.jsonl"
DS="runs/${TAG}/dataset.jsonl"
MASTER="js2jac_dataset.jsonl"
CANDS="${CANDS:-source/candidates.jsonl}"
JAC_REPO="/home/jac/repos/jac_llm_data/jaseci/jac"
PY="/home/jac/repos/jac_llm_data/.venv/bin/python"

mkdir -p "$WORK" "$BATCH"

echo "[$TAG] 1/4 prep (offset=$OFFSET limit=$LIMIT)"
set +e
$PY js2jac_prep.py --candidates "$CANDS" --offset "$OFFSET" --limit "$LIMIT" \
  --work-dir "$WORK" --profile react
rc=$?
set -e
[ "$rc" -eq 3 ] && { echo "[$TAG] no records (end of slice) — stopping"; exit 3; }
N=$(ls "$WORK"/*.json 2>/dev/null | grep -v '/_emitted' | wc -l || true)
# (|| true: with 0 records grep selects nothing -> rc=1 under pipefail, which
#  set -e turned into a silent chunk death the moment prep stopped rc=3-ing
#  on empty in-range slices. An empty slice is normal — keep going.)
echo "[$TAG] prepped $N per-file records"

echo "[$TAG] 2/5 floor-gate (jac check floors; keep compiling holes-floors, skip the composer)"
# Pilot (2026-08-16, 107 holes-records): the composer is NET-DESTRUCTIVE on
# holes-floors — 61/107 floors already `jac check`-pass, but composing all 107
# yields only 16 (it rejects/breaks 47 of the 61 sound floors, rescues 2 of 46).
# So gate floor-first: a holes-floor that already compiles goes straight to the
# dataset; only floor_BAD holes (+ none, which have no floor) reach the composer.
# FULL floors are still composed (idiomization is the corpus's purpose), but the
# guard falls back to the floor if the composer breaks one — never LOSE a valid
# record to a bad idiomization.
FLOORKEPT="runs/${TAG}/floor_kept.jsonl"
COMPOSE="$WORK/_compose"          # subset of work/ records to actually compose
$PY - "$WORK" "$COMPOSE" "$FLOORKEPT" "$JAC_REPO" "$FAITHFUL" <<'PYEOF'
import glob, json, os, sys, tempfile, subprocess
from concurrent.futures import ThreadPoolExecutor
work, compose_dir, floorkept, jac_repo = sys.argv[1:5]
faithful = "--faithful" in sys.argv[5:]
os.makedirs(compose_dir, exist_ok=True)
files = [f for f in sorted(glob.glob(os.path.join(work, "*.json")))
         if os.path.basename(f) != "report.json" and "/_" not in f]
recs = [json.load(open(f)) for f in files]
# 3GB address-space cap per jac check — same fix as step4_full_loop._run
# (Aug 20 OOM freezes). A runaway check dies as a compile-fail instead.
AS_CAP = int(os.environ.get("JAC_RLIMIT_AS_GB", "3")) << 30

def floor_compiles(code):
    if not code: return False
    with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False) as tf:
        tf.write(code); tp = tf.name
    try:
        return subprocess.run(["prlimit", f"--as={AS_CAP}", "--", "jac", "check", tp],
                              cwd=jac_repo,
                              capture_output=True, timeout=90).returncode == 0
    except Exception:
        return False
    finally:
        os.unlink(tp)

# Only HOLES-floors are floor-gated. FULL always composes (idiomize); NONE has
# no floor to gate. faithful mode keeps holes-floors in the round-trip set too.
holes = [r for r in recs if r.get("floor_mode") == "holes" and not faithful]
with ThreadPoolExecutor(max_workers=8) as ex:
    ok = list(ex.map(lambda r: floor_compiles(r.get("floor_jac")), holes))
kept_ids = set()
with open(floorkept, "w") as fh:
    for r, good in zip(holes, ok):
        if not good: continue
        kept_ids.add(r["id"])
        fh.write(json.dumps({
            "id": r["id"], "repo": r.get("repo"), "path": r.get("path"),
            "commit": r.get("commit"), "spdx": r.get("spdx"),
            "status_in": r.get("status"), "source": "js2jac_floor",
            "js": r.get("source_js"), "jac": r.get("floor_jac"),
        }) + "\n")
# Everything not floor-kept goes to the composer.
n_comp = 0
for f, r in zip(files, recs):
    if r["id"] in kept_ids: continue
    open(os.path.join(compose_dir, os.path.basename(f)), "w").write(json.dumps(r))
    n_comp += 1
print(f"  floor-gate: {len(recs)} recs -> {len(kept_ids)} floor-kept (sound, no LLM), "
      f"{n_comp} to compose ({len(holes)-len(kept_ids)} floor_BAD holes + full + none)")
PYEOF

echo "[$TAG] 3/5 pack batches (+ deterministic pre-REJECT of hopeless none-mode records)"
rm -f "$BATCH"/batch*.json      # stale batch files from an earlier pack re-compose done ids
$PY - "$COMPOSE" "$BATCH" "$CAND" "$FAITHFUL" <<'PYEOF'
import glob, json, os, sys
sys.path.insert(0, os.getcwd())  # chunk.sh cd's to scripts/js2jac_dataset
from js2jac_composer_batch import skills_for_record, pre_reject
work, out, cand, faithful_arg = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
faithful = "--faithful" in faithful_arg
pol = json.loads(open("strip_policy.json").read())
# css_always: additionally pre-reject CSS-in-JS in SYNTAX mode. Off by default —
# those are policy strip-and-keep and the LLM salvages ~15%; flip PREREJECT_CSS=1
# to trade that yield for the token cut.
css_always = os.environ.get("PREREJECT_CSS") == "1"
files = [f for f in sorted(glob.glob(os.path.join(work, "*.json")))
         if os.path.basename(f) != "report.json"]
recs = [json.load(open(f)) for f in files]

# Deterministic pre-REJECT: none-mode records the policy already condemns never
# reach the composer (cost lesson js2jac_20: 71% of LLM candidates came back
# REJECT; most were none-mode files whose converter codes say reject outright).
done = set()
if os.path.exists(cand):
    for l in open(cand):
        if l.strip(): done.add(json.loads(l)["id"])
pre = [r for r in recs if r["id"] not in done
       and pre_reject(r, pol, faithful, css_always)]
with open(cand, "a") as fh:
    for r in pre:
        done.add(r["id"])
        fh.write(json.dumps({"id": r["id"], "candidate": "REJECT"}) + "\n")
live = [r for r in recs if r["id"] not in done]
print(f"  pre-reject: {len(pre)} none-mode records condemned by policy (no LLM); "
      f"{len(live)} remain for the composer")

B = 10  # was 6: bigger batches amortize the per-call static context (agent
        # scaffolding + grounding + policy) that dominates fresh-input tokens.
        # Capped at 10 (py2jac precedent) to keep one response from truncating.
# Segment by floor_mode so batches are homogeneous: FULL-floor records (the
# model just idiomizes an existing exemplar) batch together and run LEAN, while
# none/holes records (the model generates Jac) batch together and get grounded.
# Mixing would force the whole batch grounded on one holes record. Within the
# gen group, sort by primary routed skill so adjacent records share topic guides
# -> the per-batch skill union stays small (each guide body is sent once/batch).
full = [r for r in live if r.get("floor_mode") == "full"]
gen  = [r for r in live if r.get("floor_mode") != "full"]
gen.sort(key=lambda r: (skills_for_record(r) or ["~"])[0])
n = 0
for group in (full, gen):
    for i in range(0, len(group), B):
        open(os.path.join(out, f"batch{n:03d}.json"), "w").write(json.dumps(group[i:i+B]))
        n += 1
print(f"  {len(live)} -> {n} batches ({len(full)} full / {len(gen)} gen)")
PYEOF

echo "[$TAG] 4/5 composer cleanup (MCP off, batched)"
exec 9>/tmp/composer.lock          # same lock as py2jac: one composer driver at a time
flock -w 21600 9 || { echo "[$TAG] could not acquire composer lock"; exit 4; }
$PY js2jac_composer_batch.py --batch-dir "$BATCH" --out "$CAND" \
  --model composer-2.5 --workers 6 --timeout 360 $FAITHFUL
flock -u 9

echo "[$TAG] 5/5 guard (jac check, floor-fallback) + merge floor-kept + append to $MASTER"
$PY - "$WORK" "$CAND" "$DS" "$JAC_REPO" "$FLOORKEPT" <<'PYEOF'
import json, re, subprocess, sys, tempfile, os
from pathlib import Path
sys.path.insert(0, os.getcwd())  # chunk.sh cd's to scripts/js2jac_dataset
from orm_behavioral_gate import gate_orm
work, cand, ds, jac_repo, floorkept = sys.argv[1:6]
meta = {}
for f in Path(work).glob("*.json"):
    if f.name == "report.json": continue
    r = json.load(open(f)); meta[r["id"]] = r

# 3GB address-space cap per jac check — same fix as step4_full_loop._run
# (Aug 20 OOM freezes). A runaway check dies as a compile-fail instead.
AS_CAP = int(os.environ.get("JAC_RLIMIT_AS_GB", "3")) << 30

_ok_cache = {}
def jac_ok(code):
    if not code or code == "REJECT": return False
    if code not in _ok_cache:          # was called twice per candidate uncached
        with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False) as tf:
            tf.write(code); tp = tf.name
        try:
            _ok_cache[code] = subprocess.run(
                ["prlimit", f"--as={AS_CAP}", "--", "jac", "check", tp],
                cwd=jac_repo, capture_output=True, timeout=90).returncode == 0
        except Exception:
            _ok_cache[code] = False
        finally:
            os.unlink(tp)
    return _ok_cache[code]

_GRAPH_OP = re.compile(r"-->|\+\+>|\bspawn\b|\+>:|->:|<-:|:->|:<-|\[\?:|\bdel here\b|\bhere\.|\bjobj\(")

def hollow(m, code):
    # An ORM record's job is to rewrite the DB calls against the lifted graph
    # schema. `jac check` passes a hollow `return []`/`{}` stub all the same.
    # The generic fidelity gate is the WRONG tool here (its body-mass signal
    # false-rejects faithful route->walker rewrites, which are idiomatically
    # DENSER/shorter than the JS). The persistence-specific hollowness signal:
    # a real rewrite REFERENCES a lifted node AND uses a graph operator; a stub
    # has neither. Non-ORM records skip this.
    schema = m.get("schema_jac")
    if not schema or not code:
        return False
    nodes = re.findall(r"\bnode\s+(\w+)", schema)
    uses_node = any(re.search(rf"\b{n}\b", code) for n in nodes)
    uses_graph = bool(_GRAPH_OP.search(code))
    return not (uses_node and uses_graph)

def orm_reject(m, code):
    # For ORM records: prefer the BEHAVIORAL gate (seed->invoke->assert read-back)
    # over the structural one — it catches wrong-filter/wrong-edge rewrites that
    # DO touch the graph (so pass `hollow`) but read back nothing real. Only when
    # the gate can't build a probe (no scalar entrypoint) fall back to structural.
    schema = m.get("schema_jac")
    if not schema:
        return False, "not-orm"
    verdict, why = gate_orm(schema, code, jac_repo)
    if verdict == "KEEP":
        return False, f"behavioral:{why}"
    if verdict == "REJECT":
        return True, f"behavioral:{why}"
    return hollow(m, code), f"structural-fallback:{why}"   # INCONCLUSIVE

kept = drop = rej = fallback = hollowed = behav = 0
pairs_f = open("dpo_pairs.jsonl", "a")  # next to dataset.jsonl (cwd = runs/TAG)
with open(ds, "w") as out:
    for line in open(cand):
        line = line.strip()
        if not line: continue
        c = json.loads(line)
        m = meta.get(c["id"], {})
        code, src = c.get("candidate"), "js2jac_cleaned"
        if jac_ok(code):
            rej_orm, why = orm_reject(m, code)
            if rej_orm:
                # compiles but hollow/wrong ORM rewrite — reject (the point of the lift)
                hollowed += 1; drop += 1
                if why.startswith("behavioral"): behav += 1
                continue
        if not jac_ok(code):
            # composer rejected or broke it — fall back to the floor if it compiles
            # (guards FULL floors against destructive idiomization; the pilot lesson).
            floor = m.get("floor_jac")
            if floor and jac_ok(floor):
                # DPO pair: chosen = known-good floor, rejected = broken rewrite
                pairs_f.write(json.dumps({"id": c["id"], "chosen": floor,
                                          "rejected": code,
                                          "why": "floor-fallback"}) + "\n")
                code, src, fallback = floor, "js2jac_floor_fallback", fallback + 1
            elif not c.get("candidate") or c.get("candidate") == "REJECT":
                rej += 1; continue
            else:
                drop += 1; continue
        out.write(json.dumps({
            "id": c["id"], "repo": m.get("repo"), "path": m.get("path"),
            "commit": m.get("commit"), "spdx": m.get("spdx"),
            "status_in": m.get("status"), "source": src,
            "js": m.get("source_js"), "jac": code,
        }) + "\n"); kept += 1
pairs_f.close()
# Merge the floor-kept records (holes-floors that already compiled, no LLM).
floor_kept = 0
if os.path.exists(floorkept):
    with open(ds, "a") as out:
        for line in open(floorkept):
            if line.strip(): out.write(line); floor_kept += 1
print(f"  guard: composed-kept {kept} (incl {fallback} floor-fallback), "
      f"check-fail {drop} (of which {hollowed} hollow-ORM: {behav} by behavioral gate, "
      f"{hollowed-behav} structural), rejected {rej} | "
      f"+ {floor_kept} floor-kept (no LLM) = {kept + floor_kept} total")
PYEOF

$PY - "$DS" "$MASTER" "$TAG" <<'PYEOF'
import json, sys, os
ds, master, tag = sys.argv[1:4]
rows = [json.loads(l) for l in open(ds)]
seen = set()
if os.path.exists(master):
    for l in open(master): seen.add(json.loads(l)["id"])
added = 0
with open(master, "a") as fh:
    for r in rows:
        if r["id"] not in seen:
            r["chunk"] = tag; fh.write(json.dumps(r) + "\n"); added += 1
print(f"  appended {added} new records to {master} (total now {len(seen)+added})")
PYEOF

# 6/6 repair pass: rescue check-failed candidates via model-assisted fix
# (py2jac lesson: a drop should get one repair shot + DPO pairing, not silence).
# Disable with JS2JAC_REPAIR=0.
if [ "${JS2JAC_REPAIR:-1}" = "1" ]; then
  echo "[$TAG] 6/6 repair pass"
  $PY repair_pass.py all --run-dir "runs/$TAG" --master "$MASTER" --tag "$TAG" \
    --model composer-2.5 --workers 4 --timeout 360 \
    || echo "[$TAG] repair pass failed (non-fatal)"
else
  echo "[$TAG] repair pass disabled (JS2JAC_REPAIR=0)"
fi

rm -rf "$WORK/_emitted" "$WORK/_compose" 2>/dev/null || true
echo "[$TAG] DONE"
