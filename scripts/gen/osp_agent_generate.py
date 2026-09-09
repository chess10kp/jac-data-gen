#!/usr/bin/env python3
"""Generate OSP issue_gen records via cursor-agent (py → jac → guard).

Architecture: one fresh conversation per CLI call. Records are generated
ONE AT A TIME with fully self-contained prompts, so no --resume chaining
is needed (or wanted): the ledger showed chained calls re-reading a growing
conversation prefix every call (~440K cache-read/record) while fresh calls
bill only their own payload — ~7x cheaper. Set CURSOR_OSP_RESUME=1 to
re-enable chaining if a provider makes cache truly free. Local validation gates each phase before the
next (bad py never reaches the jac lift), with per-record repair retries.

Two flows (--flow):
  py-first  (default): issue -> py+ref -> jac lift -> guards
  jac-first: issue -> OSP .jac + guards -> `jac tool jac2py` mech.py ($0)
             -> cheap call restyles mech.py into hand-rolled .py + .ref.py,
             anchored on the mechanical translation; ref asserts also run
             against mech.py as an equivalence oracle.

Env knobs:
  CURSOR_OSP_WS            workspace dir (default: empty dir — don't index junk)
  CURSOR_OSP_MODEL         phase 2 (jac lift) + repairs  [composer-2.5]
  CURSOR_OSP_MODEL_PY      phase 1 (py synth)            [composer-2.5]
  CURSOR_OSP_MODEL_GUARD   phase 3 (guard tests)         [composer-2.5-fast]
  CURSOR_OSP_TIMEOUT       per-call timeout seconds      [300]
  CURSOR_OSP_RETRIES       retries on timeout/empty      [1]
  CURSOR_OSP_RESUME        1 enables --resume chaining   [off]
  CURSOR_OSP_ISO           0 disables isolated HOME        [on]
  CURSOR_OSP_ISO_HOME      isolated home path [/tmp/cursor_iso_home]

Isolated HOME: cursor-agent auto-loads MCP servers from ~/.cursor/mcp.json
even when marked disabled — the jac MCP server injects 300-800K tokens of
docs whenever the model authors Jac. Isolation copies auth+cli-config into
a scratch HOME whose mcp.json has `jac` removed (measured 19x cheaper
auth-phase calls; refresh happens once per process start).
  CURSOR_OSP_TRIES         generation+repair tries/phase [2]

Token usage is appended to data/osp_lifts/_cost_ledger.jsonl per call,
parsed from cursor-agent session logs.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "lib"))
from llm_backend import get_backend, strip_prefix

REPO = Path(__file__).resolve().parents[2]
BASE = REPO / "data" / "osp_lifts"
IG = BASE / "issue_gen"
ASSIGN = BASE / "assignments"
SPEC = REPO / "docs" / "OSP_IDIOMIZE_TASK.md"
CONTRACT = BASE / "GEN_CONTRACT.md"

CURSOR_WS = os.environ.get("CURSOR_OSP_WS", "/tmp/cursor_osp_ws_empty")
CURSOR_TMP = os.environ.get("CURSOR_OSP_TMP", "/tmp/cursor_osp_tmp")
MODEL = os.environ.get("CURSOR_OSP_MODEL", "composer-2.5")
MODEL_PY = os.environ.get("CURSOR_OSP_MODEL_PY", "composer-2.5")
MODEL_GUARD = os.environ.get("CURSOR_OSP_MODEL_GUARD", "composer-2.5")
MODEL_PYGEN = os.environ.get("CURSOR_OSP_MODEL_PYGEN", "composer-2.5")
TIMEOUT = int(os.environ.get("CURSOR_OSP_TIMEOUT", "300"))
RETRIES = int(os.environ.get("CURSOR_OSP_RETRIES", "1"))
RESUME = os.environ.get("CURSOR_OSP_RESUME", "0") == "1"
PHASE_TRIES = int(os.environ.get("CURSOR_OSP_TRIES", "2"))
ISO = os.environ.get("CURSOR_OSP_ISO", "1") != "0"
ISO_HOME = Path(os.environ.get("CURSOR_OSP_ISO_HOME", "/tmp/cursor_iso_home"))
_ISO_READY = False


def _ensure_iso_home() -> None:
    """Scratch HOME whose mcp.json drops the jac MCP doc-bomb server."""
    global _ISO_READY
    if _ISO_READY:
        return
    cfg = ISO_HOME / ".cursor"
    xdg = ISO_HOME / ".config" / "cursor"
    cfg.mkdir(parents=True, exist_ok=True)
    xdg.mkdir(parents=True, exist_ok=True)
    src_cfg = Path.home() / ".cursor"
    for name in ("cli-config.json",):
        p = src_cfg / name
        if p.exists():
            (cfg / name).write_text(p.read_text())
    mcp_src = src_cfg / "mcp.json"
    if mcp_src.exists():
        try:
            import json as _json
            m = _json.loads(mcp_src.read_text())
            m.get("mcpServers", {}).pop("jac", None)
            (cfg / "mcp.json").write_text(_json.dumps(m, indent=2))
        except (ValueError, OSError):
            (cfg / "mcp.json").write_text('{"mcpServers": {}}')
    else:
        (cfg / "mcp.json").write_text('{"mcpServers": {}}')
    auth = Path.home() / ".config" / "cursor" / "auth.json"
    if auth.exists():
        (xdg / "auth.json").write_text(auth.read_text())
    _ISO_READY = True
LEDGER = BASE / "_cost_ledger.jsonl"
LAST_CONV: dict[str, str | None] = {"id": None}


def _backend_call(system: str, user: str, timeout: int, model: str, phase: str) -> str:
    """Unified dispatch via llm_backend — pi/cursor/zen/openrouter swappable.
    Backend selected by CURSOR_OSP_BACKEND / OSP_BACKEND (pi|cursor|zen|openrouter|auto).
    Auto keeps backward compat: luna->pi, *-free->zen/openrouter, else cursor."""
    hint = os.environ.get("CURSOR_OSP_BACKEND", os.environ.get("OSP_BACKEND", "auto"))
    be = get_backend(hint, model)
    core = strip_prefix(model)
    tries = max(2, RETRIES + 1)
    text, err, usage = be.call(system, user, core, timeout, tries=tries)
    LEDGER.parent.mkdir(parents=True, exist_ok=True)
    with LEDGER.open("a") as fh:
        fh.write(json.dumps({
            "ts": time.time(), "phase": phase, "model": model,
            "backend": be.name, "attempt": 0, "resume": False,
            "ms": usage.get("ms", 0),
            "input": usage.get("inputTokens", 0),
            "output": usage.get("outputTokens", 0),
            "cache_read": usage.get("cacheReadTokens", 0),
        }) + "\n")
    if err and not text:
        print(f"{be.name}_call FAIL [{phase}]: {err[:160]}", flush=True)
        return ""
    # preserve conversation id if backend exposed it
    cid = usage.get("conversation_id")
    if cid:
        LAST_CONV["id"] = cid
    else:
        LAST_CONV["id"] = None
    return text or ""


# compat shims — old call sites import these names
def _use_pi(model: str) -> bool:  # noqa: D401
    return get_backend(os.environ.get("CURSOR_OSP_BACKEND", "auto"), model).name == "pi"


def pi_call(system: str, user: str, timeout: int = TIMEOUT, model: str = MODEL, phase: str = "?") -> str:
    return _backend_call(system, user, timeout, model, phase)


PY_FENCE = re.compile(r"```python\s*\n(.*?)```", re.S)
JAC_FENCE = re.compile(r"```jac\s*\n(.*?)```", re.S)


def stem_for(repo: str, issue: int) -> str:
    owner, name = repo.split("/", 1)
    return f"iss_{owner}__{name.replace('/', '__')}__{issue}"


def ledger_since(t0: float) -> dict:
    if not LEDGER.exists():
        return {"calls": 0, "input": 0, "output": 0, "cache_read": 0, "wall_s": 0.0}
    rows = []
    for line in LEDGER.read_text().splitlines():
        if line.strip():
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    rows = [r for r in rows if r.get("ts", 0) >= t0]
    return {
        "calls": len(rows),
        "input": sum(r.get("input", 0) for r in rows),
        "output": sum(r.get("output", 0) for r in rows),
        "cache_read": sum(r.get("cache_read", 0) for r in rows),
        "wall_s": round(sum(r.get("ms", 0) for r in rows) / 1000, 1),
    }


def cursor_call(system: str, user: str, timeout: int = TIMEOUT,
                model: str = MODEL, phase: str = "?",
                resume_id: str | None = None) -> str:
    # resume_id kept for API compat — generation is stateless (one-shot prompts
    # carry full context). Backend handles its own retry/ISO/workspace.
    _ = resume_id
    return _backend_call(system, user, timeout, model, phase)


def run(cmd: list[str], cwd: Path, timeout: int = 180,
         env: dict | None = None) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True,
                           timeout=timeout, env=env)
        return p.returncode, (p.stdout + p.stderr)[-3000:]
    except subprocess.TimeoutExpired:
        return 124, "timeout"


def load_spec_excerpt() -> str:
    parts = []
    if CONTRACT.exists():
        parts.append(CONTRACT.read_text()[:6000])
    if SPEC.exists():
        parts.append(SPEC.read_text()[:8000])
    return "\n\n".join(parts)


SYSTEM = """You are an expert Jac OSP engineer generating training records.
Follow GEN_CONTRACT.md and OSP_IDIOMIZE_TASK.md v2.1 exactly.

HARD RULES:
- Do NOT run shell commands, read files, or call any tools. Everything you
  need is in this prompt; work purely from the given context.
- Output ONLY fenced code blocks as requested (no prose).
- Python: hand-rolled graph machinery (adjacency dicts, deque/BFS, parent refs).
- Jac: idiomatic OSP with node/edge/walker; NO def-body docstrings; NO pass;
  NO bare `report` statement (walker reports via `print` or `here.field`/`self.field` mutation + `disengage`/`visit`; `report` is a keyword, not a statement);
  every `with entry` MUST `root spawn Walker;` and every walker MUST `print` so the demo has visible output;
  cycle policy via claim-map + skip (never disengage on revisit).
- Public API names/signatures/return shapes match Python EXACTLY.
- Tests: deterministic, sorted/multiset where order unspecified.

JAC DIALECT (verified against jac 0.36.1 — follow EXACTLY):
- node N { has f: str; has g: int = 0; }   edge E {}
- CREATE NODES by constructor + connect, NEVER `spawn Node(...)`:
    nd = N(f="x");  root ++> nd;            # untyped connect
    a +>:E:+> b;                            # typed edge connect
  `spawn` LAUNCHES WALKERS ONLY, from a graph location:
    w = nd spawn W(claimed={});             # returns walker, read w.found after
- walker W {
    has claimed: dict[str, bool] = {};      # typed has-field with literal default OK
    can step with N entry {
      if here.cid in self.claimed { skip; }  # cycle policy: claim-map + skip
      for ch in [here ->:E:->][?:N] { ... }  # typed edge navigation
      visit :0: [kid];                       # front-insert visit for DFS order
    }
  }
- ONE `can X with T entry` per name per walker — a second handler for a
  different node type MUST use a distinct ability name:
    can step_a with A entry { ... }  can step_b with B entry { ... }
  (duplicate `can step with ...` twice in one walker = E0076, FAILS)
- `root` is a RESERVED keyword: NEVER a def param, local, or field name
  (E0013, FAILS). Name it `root_node` / `graph_root` instead.
- module-level helpers: def helper(x: str) -> list[N] { ... return xs; }
- locals NEED type annotations when assigned empty/ambiguous literals:
  kids: list[N] = [];  seen: dict[str, int] = {};   # bare `x = {};`/`x = [];` FAILS
- NO dict/list comprehensions — build with explicit for loops
- def params take NO mutable defaults (= [] / = {}): use `x: list | None = None`
  and assign inside the body
- None (never null), True/False; sorted(xs), len(xs), xs.append(...) work;
  `store["m"] as dict[str, N]` casts
- test "name" { ...; assert cond; }
- no docstrings inside defs (use # comments); no `pass;`
"""


def prompt_py(rec: dict, stem: str, err: str = "") -> str:
    fix = ""
    if err:
        fix = (f"\nYour previous attempt FAILED validation:\n{err}\n"
               f"Regenerate BOTH blocks fully corrected. The ref harness must "
               f"only reference names the module actually defines.\n")
    return (
        f"GitHub issue: {rec['repo']}#{rec['issue']}\n"
        f"Title: {rec['title']}\n"
        f"Signals: {', '.join(rec.get('signals', []))}\n\n"
        f"Issue body (excerpt):\n{rec.get('body', '')[:4000]}\n\n"
        f"Generate TWO ```python blocks:\n"
        f"1. MODULE `{stem}.py` — synthetic before-code (~50-90 lines) citing "
        f"{rec['repo']}#{rec['issue']} in module docstring. Include genuine "
        f"hand-rolled traversal machinery.\n"
        f"2. REF HARNESS `{stem}.ref.py` body only (no imports wrapper) — "
        f"exercises EVERY public function with inline asserts on a deterministic "
        f"fixture. Will be wrapped automatically.\n{fix}"
    )


def prompt_jac(rec: dict, py_src: str, err: str = "") -> str:
    fix = ""
    if err:
        fix = (f"\nYour previous candidate FAILED `jac check`:\n{err[-600:]}\n"
               f"Regenerate the full corrected ```jac block.\n")
    return (
        f"Issue: {rec['repo']}#{rec['issue']} — {rec['title']}\n\n"
        f"Python source (ground truth API + semantics):\n```python\n{py_src}\n```\n\n"
        f"Rewrite as idiomatic Jac OSP lift in ONE ```jac block.\n"
        f"Preserve exact public def names/signatures/return shapes.\n"
        f"Eliminate adjacency dicts, deque loops, manual recursion plumbing.\n{fix}"
    )


def prompt_guard(rec: dict, py_src: str, jac_src: str, err: str = "") -> str:
    fix = ""
    if err:
        fix = (f"\nThe record FAILED validation:\n{err[-600:]}\n"
               f"Regenerate the hidden tests corrected. Tests must only use the "
               f"candidate's public API and deterministic values.\n")
    return (
        f"Issue: {rec['repo']}#{rec['issue']}\n\n"
        f"Python source:\n```python\n{py_src}\n```\n\n"
        f"Jac candidate (already validated by jac check):\n```jac\n{jac_src}\n```\n\n"
        f"Generate hidden ```jac test blocks ONLY (3-6 tests) to append after "
        f"the candidate. Adversarial: diamond revisit, unknown-id tolerance, "
        f"edge cases not in ref harness. Syntax: test \"name\" {{ assert (...);; }}\n{fix}"
    )


# ------------------------------------------------------------- jac-first ---

def prompt_auth(rec: dict, stem: str, err: str = "") -> str:
    fix = ""
    if err:
        fix = (f"\nYour previous attempt FAILED validation:\n{err[-600:]}\n"
               f"Regenerate BOTH blocks fully corrected.\n")
    return (
        f"GitHub issue: {rec['repo']}#{rec['issue']}\n"
        f"Title: {rec['title']}\n"
        f"Signals: {', '.join(rec.get('signals', []))}\n\n"
        f"Issue body (excerpt):\n{rec.get('body', '')[:4000]}\n\n"
        f"Author an idiomatic Jac OSP training record directly from this issue.\n"
        f"Output TWO fenced ```jac blocks, nothing else:\n"
        f"1. PROGRAM `{stem}.jac` — full idiomatic OSP program: node/edge "
        f"declarations, walkers, public defs matching the issue's domain "
        f"(~40-90 lines). NO test blocks inside. Cycle policy via claim-map "
        f"+ skip.\n"
        f"2. TESTS — ONLY 3-6 `test \"name\" {{ assert (...);; }}` blocks, "
        f"adversarial: diamond revisit, unknown-id tolerance, edge cases.\n{fix}"
    )


def prompt_pygen(rec: dict, stem: str, mech_py: str, guard_tests: str, err: str = "") -> str:
    fix = ""
    if err:
        fix = (f"\nYour previous attempt FAILED validation:\n{err[-600:]}\n"
               f"Regenerate BOTH blocks fully corrected — the ref harness must "
               f"only reference names the module actually defines.\n")
    return (
        f"Issue: {rec['repo']}#{rec['issue']} — {rec['title']}\n\n"
        f"Below is a mechanical Python translation (runtime-shim style) of an "
        f"idiomatic Jac OSP program, plus its hidden Jac tests. Produce the "
        f"\"before-code\": the same behavior as NAIVE hand-rolled Python.\n\n"
        f"Mechanical translation (semantic ground truth — SAME public API):\n"
        f"```python\n{mech_py}\n```\n\n"
        f"Jac tests (behaviors the module must satisfy):\n```jac\n{guard_tests}\n```\n\n"
        f"Output TWO ```python blocks:\n"
        f"1. MODULE `{stem}.py` (~40-90 lines) — hand-rolled style ONLY: "
        f"adjacency dicts, collections.deque BFS/DFS, parent refs, manual "
        f"recursion plumbing, visited sets. NO jaclib/jac imports, NO "
        f"Node/Edge/Walker/GraphQuery classes. Same public def names/signatures/"
        f"return shapes as the mechanical translation, EXACTLY. Cite "
        f"{rec['repo']}#{rec['issue']} in the module docstring.\n"
        f"2. REF HARNESS body only — inline asserts exercising EVERY public "
        f"function on a deterministic fixture mirroring the Jac tests.\n{fix}"
    )


def wrap_ref(stem: str, body: str) -> str:
    return f'''"""Reference harness for {stem}."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("{stem}.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
{body.strip()}
print("{stem} ref OK")
'''


def write_py(stem: str, py: str, ref_body: str) -> None:
    IG.mkdir(parents=True, exist_ok=True)
    (IG / f"{stem}.py").write_text(py.strip() + "\n")
    (IG / f"{stem}.ref.py").write_text(wrap_ref(stem, ref_body))


def write_jac(stem: str, jac: str) -> None:
    (IG / f"{stem}.jac").write_text(jac.strip() + "\n")


def write_guard(stem: str, jac: str, tests: str) -> None:
    (IG / f"{stem}_guard.jac").write_text(jac.rstrip() + "\n\n" + tests.strip() + "\n")


def validate(stem: str) -> tuple[bool, str]:
    for label, cmd in [
        ("ref", ["python3", f"issue_gen/{stem}.ref.py"]),
        ("check", ["jac", "check", f"issue_gen/{stem}.jac"]),
        ("test", ["jac", "test", f"issue_gen/{stem}_guard.jac"]),
    ]:
        rc, out = run(cmd, BASE, timeout=300 if label == "test" else 120)
        if rc != 0:
            return False, f"{label}: {out[-500:]}"
    return True, "ok"


def jac_check(stem: str) -> tuple[bool, str]:
    rc, out = run(["jac", "check", f"issue_gen/{stem}.jac"], BASE)
    return rc == 0, out


def ref_check(stem: str) -> tuple[bool, str]:
    rc, out = run(["python3", f"issue_gen/{stem}.ref.py"], BASE)
    return rc == 0, out


def jac_validate(stem: str) -> tuple[bool, str]:
    """Jac-side validation only (check + guard test) — no py required."""
    rc, out = run(["jac", "check", f"issue_gen/{stem}.jac"], BASE)
    if rc != 0:
        return False, f"check: {out[-300:]}"
    rc, out = run(["jac", "test", f"issue_gen/{stem}_guard.jac"], BASE, timeout=300)
    if rc != 0:
        return False, f"test: {out[-300:]}"
    return True, "ok"


def mech_translate(stem: str) -> str | None:
    """`jac tool jac2py` — mechanical runtime-shim Python of the record's jac."""
    try:
        p = subprocess.run(["jac", "tool", "jac2py", str(IG / f"{stem}.jac")],
                           capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return None
    return p.stdout.strip() if p.returncode == 0 and p.stdout.strip() else None


MECH_REPO_JAC = os.environ.get(
    "CURSOR_OSP_MECH_PY",
    str(REPO / "jaseci" / "jac"),
)
_MECH_ENV: dict | None | bool | None = None  # None = unprobed, False = unavailable


def mech_env() -> dict | None:
    """Env whose python3 can import jaclang (user site has it disabled)."""
    global _MECH_ENV
    if _MECH_ENV is None:
        _MECH_ENV = False
        for pp in (None, MECH_REPO_JAC):
            env = {**os.environ, **({"PYTHONPATH": pp} if pp else {})}
            try:
                p = subprocess.run(
                    ["python3", "-c", "import jaclang.jac0core.jaclib"],
                    capture_output=True, text=True, timeout=30, env=env)
            except subprocess.TimeoutExpired:
                continue
            if p.returncode == 0:
                _MECH_ENV = env
                break
    return _MECH_ENV or None


def ref_vs_mech(stem: str, ref_body: str) -> tuple[bool, str]:
    """Equivalence oracle: run the ref asserts against the mech translation too."""
    env = mech_env()
    if env is None:
        return True, "oracle unavailable (no python3 with jaclang)"
    mech = mech_translate(stem)
    if mech is None:
        return True, "mech unavailable"
    d = Path("/tmp/osp_mech")
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{stem}.py").write_text(mech + "\n")
    (d / f"{stem}.ref.py").write_text(wrap_ref(stem, ref_body))
    rc, out = run(["python3", f"{stem}.ref.py"], d, env=env)
    return rc == 0, out[-300:]


def extract_pys(text: str) -> list[str]:
    return [m.group(1).strip() for m in PY_FENCE.finditer(text)]


def extract_tests(text: str) -> str:
    return "\n\n".join(m.group(1).strip() for m in JAC_FENCE.finditer(text))


def complete(stem: str) -> bool:
    if not ((IG / f"{stem}.py").exists() and (IG / f"{stem}_guard.jac").exists()):
        return False
    return validate(stem)[0]


def clear_downstream(stem: str) -> None:
    """Drop stale candidate/guard — they cannot match regenerated py."""
    for junk in (f"{stem}.jac", f"{stem}_guard.jac"):
        p = IG / junk
        if p.exists():
            p.unlink()


def generate_record(rec: dict, conv: str | None, spec: str, force: bool,
                    flow: str = "py-first") -> tuple[bool, str | None]:
    if flow in ("jac-first", "jac-only"):
        return generate_record_jac_first(rec, conv, spec, force, flow)
    """One record through py → jac → guard, chaining calls in one conversation.

    Returns (ok, conversation id). Every phase is validated locally before
    the next one runs; failures retry with the error appended (PHASE_TRIES).
    """
    stem = stem_for(rec["repo"], rec["issue"])
    conv = conv or None

    def call(system: str, user: str, model: str, phase: str) -> str:
        nonlocal conv
        out = cursor_call(system, user, model=model, phase=phase, resume_id=conv)
        conv = LAST_CONV["id"] or conv
        return out

    # -- phase 1: py + ref (reuse if the leftovers still pass) --------------
    py_src: str | None = None
    if (IG / f"{stem}.py").exists() and (IG / f"{stem}.ref.py").exists():
        ok, _ = ref_check(stem)
        if ok:
            py_src = (IG / f"{stem}.py").read_text()
            print(f"{stem}: reuse py/ref")
    if py_src is None:
        err = ""
        for attempt in range(PHASE_TRIES):
            out = call(SYSTEM + "\n" + spec[:4000], prompt_py(rec, stem, err),
                       MODEL_PY, "py" if not err else "py-fix")
            blocks = extract_pys(out)
            if len(blocks) >= 2:
                write_py(stem, blocks[0], blocks[1])
                clear_downstream(stem)
                ok, err = ref_check(stem)
                if ok:
                    py_src = blocks[0]
                    break
            else:
                err = f"expected 2 python blocks, got {len(blocks)}"
        if py_src is None:
            print(f"{stem}: FAIL py synth ({err.splitlines()[-1] if err else '?'})")
            return False, conv

    # -- phase 2: jac lift (reuse if it still passes jac check) -------------
    jac_ok = False
    if not force and (IG / f"{stem}.jac").exists() and jac_check(stem)[0]:
        jac_ok = True
        print(f"{stem}: reuse jac")
    if not jac_ok:
        err = ""
        for attempt in range(PHASE_TRIES):
            out = call(SYSTEM, prompt_jac(rec, py_src, err),
                       MODEL, "jac" if not err else "jac-fix")
            m = JAC_FENCE.search(out)
            if m:
                write_jac(stem, m.group(1).strip())
                ok, err = jac_check(stem)
                if ok:
                    jac_ok = True
                    break
            else:
                err = "no ```jac block in output"
        if not jac_ok:
            print(f"{stem}: FAIL jac lift ({(err or '?').splitlines()[-1][:120]})")
            return False, conv
    jac_src = (IG / f"{stem}.jac").read_text()

    # -- phase 3: guard tests + full validation ------------------------------
    for attempt in range(PHASE_TRIES):
        if (IG / f"{stem}_guard.jac").exists() and not attempt and validate(stem)[0]:
            print(f"{stem}: reuse guard")
            return True, conv
        err = ""
        out = call(SYSTEM, prompt_guard(rec, py_src, jac_src, err),
                   MODEL_GUARD, "guard")
        tests = extract_tests(out)
        if not tests.strip():
            continue
        write_guard(stem, jac_src, tests)
        ok, err = validate(stem)
        if ok:
            return True, conv
        for _ in range(PHASE_TRIES - 1):
            out = call(SYSTEM, prompt_guard(rec, py_src, jac_src, err),
                       MODEL_GUARD, "guard-fix")
            tests = extract_tests(out)
            if not tests.strip():
                continue
            write_guard(stem, jac_src, tests)
            ok, err = validate(stem)
            if ok:
                return True, conv
    print(f"{stem}: FAIL validation ({(err or '?').splitlines()[-1][:120]})")
    return False, conv


def generate_record_jac_first(rec: dict, conv: str | None, spec: str,
                             force: bool, flow: str = "jac-first") -> tuple[bool, str | None]:
    """jac-first: author OSP jac + guards, then jac2py anchors the before-code.

    issue -> OSP .jac + tests (full model)
    .jac  -> mech.py via `jac tool jac2py` ($0)
    mech.py + tests -> hand-rolled .py + .ref.py (cheap model, anchored)
    ref asserts also run against mech.py as an equivalence oracle.
    """
    stem = stem_for(rec["repo"], rec["issue"])
    conv = conv or None

    def call(system: str, user: str, model: str, phase: str) -> str:
        nonlocal conv
        out = cursor_call(system, user, model=model, phase=phase, resume_id=conv)
        conv = LAST_CONV["id"] or conv
        return out

    # -- phase A: author idiomatic OSP program + hidden tests ----------------
    authed = False
    if (not force and (IG / f"{stem}.jac").exists()
            and (IG / f"{stem}_guard.jac").exists() and jac_validate(stem)[0]):
        authed = True
        print(f"{stem}: reuse jac/guards")
    if not authed:
        err = ""
        for _ in range(PHASE_TRIES):
            out = call(SYSTEM + "\n" + spec[:4000], prompt_auth(rec, stem, err),
                       MODEL, "auth" if not err else "auth-fix")
            blocks = [m.group(1).strip() for m in JAC_FENCE.finditer(out)]
            if len(blocks) >= 2:
                write_jac(stem, blocks[0])
                write_guard(stem, blocks[0], "\n\n".join(blocks[1:]))
                ok, err = jac_validate(stem)
                if ok:
                    authed = True
                    break
            else:
                err = f"expected >=2 jac blocks, got {len(blocks)}"
        if not authed:
            print(f"{stem}: FAIL auth ({(err or '?').splitlines()[-1][:120]})")
            return False, conv
    if flow == "jac-only":
        return True, conv
    jac_src = (IG / f"{stem}.jac").read_text()
    guard_src = (IG / f"{stem}_guard.jac").read_text()
    sep = jac_src.rstrip()
    tests_part = guard_src.split(sep, 1)[1].strip() if sep and sep in guard_src else guard_src

    # -- phase B: mechanical translation (deterministic) ---------------------
    mech = mech_translate(stem)
    if mech is None:
        print(f"{stem}: FAIL jac2py")
        return False, conv

    # -- phase C: hand-rolled before-code + ref, anchored on mech ------------
    py_done = False
    if ((IG / f"{stem}.py").exists() and (IG / f"{stem}.ref.py").exists()
            and complete(stem)):
        py_done = True
        print(f"{stem}: reuse py/ref")
    if not py_done:
        err = ""
        for _ in range(PHASE_TRIES):
            out = call(SYSTEM, prompt_pygen(rec, stem, mech, tests_part, err),
                       MODEL_PYGEN, "pygen" if not err else "pygen-fix")
            blocks = extract_pys(out)
            if len(blocks) >= 2:
                write_py(stem, blocks[0], blocks[1])
                ok, err = ref_check(stem)
                if ok:
                    mok, mout = ref_vs_mech(stem, blocks[1])
                    if not mok:
                        print(f"{stem}: note — ref also fails on mech: "
                              f"{(mout or '?').splitlines()[-1][:80]}")
                    py_done = True
                    break
                err = f"ref: {err}"
            else:
                err = f"expected 2 python blocks, got {len(blocks)}"
        if not py_done:
            print(f"{stem}: FAIL pygen ({(err or '?').splitlines()[-1][:120]})")
            return False, conv
    return True, conv


def generate_chunk(recs: list[dict], force: bool = False,
                   flow: str = "py-first") -> tuple[int, int]:
    todo: list[dict] = []
    for rec in recs:
        stem = stem_for(rec["repo"], rec["issue"])
        if not force and complete(stem):
            print(f"{stem}: already complete")
            continue
        todo.append(rec)
    if not todo:
        return len(recs), 0

    t0c = time.time()
    spec = load_spec_excerpt()
    conv: str | None = None
    ok_n = fail_n = 0
    for rec in todo:
        ok, conv = generate_record(rec, conv, spec, force, flow)
        ok_n, fail_n = (ok_n + 1, fail_n) if ok else (ok_n, fail_n + 1)

    cost = ledger_since(t0c)
    print(f"chunk[{len(todo)}] cost: {cost['calls']} calls | in {cost['input']/1e3:.0f}K "
          f"out {cost['output']/1e3:.0f}K cache {cost['cache_read']/1e6:.2f}M "
          f"| llm {cost['wall_s']}s", flush=True)
    return ok_n, fail_n


def load_batch(batch: int) -> list[dict]:
    path = ASSIGN / f"issues_{batch}_assign.json"
    if not path.exists():
        raise FileNotFoundError(path)
    return json.loads(path.read_text())["records"]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--batch", type=int, help="assignment batch number")
    ap.add_argument("--repo", help="owner/repo for single record")
    ap.add_argument("--issue", type=int, help="issue number for single record")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--chunk", type=int, default=10,
                    help="records per conversation chain (grouping only)")
    ap.add_argument("--flow", choices=["py-first", "jac-first", "jac-only"], default="jac-only",
                    help="jac-only (default): author OSP jac + guards, no python side; "
                         "jac-first: continue with jac2py-anchored before-code")
    args = ap.parse_args()

    if args.batch:
        recs = load_batch(args.batch)[args.offset:]
        if args.limit:
            recs = recs[: args.limit]
    elif args.repo and args.issue:
        recs = [{"repo": args.repo, "issue": args.issue, "title": "", "body": "", "signals": []}]
    else:
        ap.error("need --batch or --repo + --issue")

    ok_n = fail_n = 0
    for i in range(0, len(recs), max(1, args.chunk)):
        o, f = generate_chunk(recs[i : i + max(1, args.chunk)], force=args.force,
                              flow=args.flow)
        ok_n += o
        fail_n += f
        time.sleep(1)
    print(f"\nDONE: {ok_n} ok, {fail_n} fail")
    return 1 if fail_n else 0


if __name__ == "__main__":
    sys.exit(main())
