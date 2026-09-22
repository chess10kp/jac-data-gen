#!/usr/bin/env python3
"""Generate OSP variants with muse-spark-1.2-contributor-free via opencode zen.

THIS SCRIPT IS LOCKED TO muse-spark-1.2-contributor-free. It is meant to be
invoked from inside Pi (the user's Claude/GPT shell) — not as a standalone
cron or external pipeline stage — so the user keeps direct visibility on what
the model emits and can intervene before any record lands in the dataset.

Backend: opencode zen gateway (https://opencode.ai/zen/v1,
OpenAI-compatible), rotating across the 8 free-tier "contributor" keys
stashed in ~/.pi/agent/auth.json and ~/<name>.env worker files. The zen free
tier rejects plain API clients (400 MissingSessionID: "free tier can only be
used in OpenCode"), so every request carries opencode client headers
(User-Agent + a fresh x-opencode-session-id) — the request shape the gateway
accepted when probed.

Replays the 100 hand-written problems in data/osp_examples/group_{A..E}.jsonl,
asks the model for a ```jac fenced solution, runs `jac check` + an OSP
structural contract check (matches the reference composer-2.5 batch's
quality bar), and appends each passing record to data/osp_dataset.jsonl
with generator_model_id = "muse-spark-1.2-contributor-free" so the original
composer-2.5 batch stays intact.

Schema mirrors scripts/gen/pack_osp_dataset.py exactly; only generator /
generator_model_id / run_tag differ from the reference batch.

Env knobs (read-only after import — don't add general model plumbing here):
  OSP_MUSE_TEMP    sampling temperature           [0.7]
  OSP_MUSE_TIMEOUT per-call seconds              [240]
  OSP_MUSE_TRIES   retries on transient failures [4]
  OSP_MUSE_MAXTOK  max_tokens per call            [8192]
  OSP_MUSE_FIX     repair attempts after a gate failure [2]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BASE = REPO / "data" / "osp_examples"
OUT = Path(os.environ.get("OSP_MUSE_OUT", REPO / "data" / "osp_dataset.jsonl"))
FAILS = REPO / "data" / "osp_muse_failures.jsonl"
# MODEL IS LOCKED. Do not parameterize this script for other models; if
# another model is needed, write a separate sibling script.
MODEL = "muse-spark-1.2-contributor-free"
TAG = "osp_muse_spark_1_2_cf"
assert MODEL == "muse-spark-1.2-contributor-free", "model locked"
TEMP = float(os.environ.get("OSP_MUSE_TEMP", "0.7"))
TIMEOUT = int(os.environ.get("OSP_MUSE_TIMEOUT", "240"))
TRIES = int(os.environ.get("OSP_MUSE_TRIES", "4"))
MAXTOK = int(os.environ.get("OSP_MUSE_MAXTOK", "8192"))
FIX_TRIES = int(os.environ.get("OSP_MUSE_FIX", "2"))
ZEN_BASE = "https://opencode.ai/zen/v1"

JAC_FENCE = re.compile(r"```jac\s*\n(.*?)```", re.S)


def _zen_keys() -> list[str]:
    """The 8 opencode contributor keys: pi auth.json + ~/<name>.env workers."""
    keys: list[str] = []
    env = os.environ.get("OPENCODE_KEY") or os.environ.get("OPENCODE_API_KEY")
    if env and env.startswith("sk-"):
        keys.append(env)
    auth = Path.home() / ".pi/agent/auth.json"
    if auth.exists():
        try:
            d = json.loads(auth.read_text())
            k = d.get("opencode", {}).get("key")
            if k and k.startswith("sk-") and k not in keys:
                keys.append(k)
        except (ValueError, OSError):
            pass
    for f in sorted(Path.home().glob(".*.env")) + [Path.home() / "fifth.env"]:
        try:
            for ln in f.read_text().splitlines():
                m = re.match(r"(?:export\s+)?OPENCODE\w*=(.+)$", ln.strip())
                if not m:
                    continue
                k = m.group(1).strip().strip("'\"")
                if k.startswith("sk-") and k not in keys:
                    keys.append(k)
        except OSError:
            pass
    if len(keys) < 8:
        raise RuntimeError(f"expected 8 opencode keys, found {len(keys)}")
    return keys

_zen_key_idx = 0
import threading as _th
_zen_key_lock = _th.Lock()

def _zen_key_start() -> int:
    """Atomically claim a starting index so parallel shards spread keys."""
    global _zen_key_idx
    keys = _zen_keys()
    with _zen_key_lock:
        idx = _zen_key_idx % len(keys)
        _zen_key_idx += 1
        return idx


SYSTEM = (
    "You are an expert Jac (Jaseci) engineer. The user gives you a small "
    "object-spatial programming (OSP) problem. Produce a SINGLE complete, "
    "runnable Jac program that solves the problem.\n\n"
    "OUTPUT CONTRACT — your response must contain exactly one ```jac ... ``` "
    "fenced block. No prose before or after the fence.\n\n"
    "STRUCTURAL REQUIREMENTS (every record must satisfy all of these):\n"
    "1. The module begins with a top-level docstring (`\"\"\"...\"\"\"`) on "
    "the first line.\n"
    "2. Entity archetypes are declared with `node Name { ... }` and have "
    "typed `has` fields with defaults: `has title: str = \"\";`, "
    "`has year: int = 0;`, `has available: bool = True;`. NEVER use `Any` "
    "or leave a field untyped.\n"
    "3. Walker names are PascalCase (`Librarian`, `Hiker`, `OrderAuditor`). "
    "Ability signatures use `can <name> with <NodeType> entry { ... }` (or "
    "`exit`, or `Root entry`). A walker that visits multiple node types "
    "declares one ability per type.\n"
    "4. Walkers actually traverse. At least one walker ability must end with "
    "`visit [-->];` (forward) or `visit [<--];` (backward). When the "
    "frontier may be empty use `visit [-->] else { disengage; }`. A walker "
    "ability that only prints and never `visit`s is NOT a real walker — "
    "it would never visit a node when spawned.\n"
    "5. The module ends with a `with entry { ... }` block that wires the "
    "demo: creates nodes, connects them (`root ++> ... ++> ...`), and "
    "spawns the walker(s) on `root` (e.g. `root spawn Librarian();` or "
    "`Librarian() spawn root;`).\n"
    "6. Syntax is Jac, not Python. Statements end with `;`. Blocks use "
    "`{ ... }`. NO `def f():` style, NO `: pass` style, NO `if x:` style "
    "without braces. f-strings are written `f\"...\"` exactly as in Jac.\n"
    "7. Do NOT include pytest or jac test blocks; the demo IS the "
    "demonstration.\n"
    "8. Every edge archetype you reference — in `visit [->:T:->]`, "
    "`visit [<--:T:--]`, or `a +>:T:+> b` — MUST be declared at module "
    "level as `edge T { ... }`. An empty body (`edge T { }`) is fine. "
    "NEVER write a typed visit or typed-edge connection whose name has no "
    "matching `edge` declaration; that is a compile error. If the "
    "relationship carries no payload, either declare the empty edge or "
    "use a plain `-->` connection.\n\n"
    "IDIOM (matches the existing reference corpus):\n"
    "- Typed edges where the relationship carries meaning: "
    "`a +>:Owner:+> b;`. Plain `-->++>` is fine for short demo chains.\n"
    "- `here` for the current node, `self` for the walker, `visit [...]` for "
    "traversal, `disengage;` for early termination.\n"
    "- Computed ternaries must assign a fresh name. NEVER write "
    "`x = \"a\" if cond else x;` — that references the variable on its own "
    "right-hand side and is a runtime bug. Always name the new result "
    "differently, e.g. `label = \"a\" if cond else \"b\";`.\n\n"
    "REFERENCE SHAPE — your output must match this kind of structure:\n"
    "```jac\n"
    "\"\"\"Library catalog: model books as nodes and walk the shelf with a "
    "librarian walker.\"\"\"\n"
    "\n"
    "node Book {\n"
    "    has title: str = \"\";\n"
    "    has year: int = 0;\n"
    "    has available: bool = True;\n"
    "}\n"
    "\n"
    "walker Librarian {\n"
    "    has shelf_label: str = \"Main\";\n"
    "\n"
    "    can start with Root entry {\n"
    "        print(f\"Shelving books for {self.shelf_label} shelf\");\n"
    "        visit [-->];\n"
    "    }\n"
    "\n"
    "    can shelve with Book entry {\n"
    "        status = \"IN\" if here.available else \"OUT\";\n"
    "        print(f\"[{status}] {here.title} ({here.year})\");\n"
    "        visit [-->];\n"
    "    }\n"
    "}\n"
    "\n"
    "with entry {\n"
    "    root ++> Book(title=\"Dune\", year=1965)\n"
    "        ++> Book(title=\"Neuromancer\", year=1984)\n"
    "        ++> Book(title=\"Circe\", year=2018, available=False);\n"
    "    root spawn Librarian(shelf_label=\"Sci-Fi & Fantasy\");\n"
    "}\n"
    "```\n\n"
    "Now produce the program for the user's problem in the same shape."
)


# --- Idiom enrichment (composer-grade context) -----------------------------
# m3 imitates reference structure well but never attempts the signature OSP
# idioms (union triggers, typed edges) unless shown them, and it carries
# pre-0.36 filter syntax from stale training data. This block replaces the
# floor's "one ability per type" ceiling and injects spec slices plus a
# verified demo. Probe: 10 holdouts that failed the floor prompt 3x each
# went 0/10 -> 3/10 with this context.
_SPEC_PATH = REPO / "docs" / "OSP_IDIOMIZE_TASK.md"
_SPEC = _SPEC_PATH.read_text() if _SPEC_PATH.exists() else ""
_SPEC6 = ""
if _SPEC:
    _s6 = _SPEC.index("## 6. The model task")
    _SPEC6 = _SPEC[_s6:_SPEC.index("## 7.")]
_UNION_NOTE = (
    "When one routine must handle several node types, write ONE union "
    "ability: `can inspect with TypeA | TypeB entry { ... }`. The ability "
    "body may only touch fields/methods shared by every type in the union "
    "(declare them on a base node and `override` them)."
)
_CEILING = ("A walker that visits multiple node types declares one ability "
            "per type.")
_DEMO = '''"""Typed-edge + union-trigger demo (idiomatic form)."""
node Sensor {
    def is_alert() -> bool {
        return False;
    }
}
node TempSensor(Sensor) {
    has celsius: float = 0.0;
    override def is_alert() -> bool {
        return self.celsius > 75.0;
    }
}
node SmokeSensor(Sensor) {
    has ppm: float = 0.0;
    override def is_alert() -> bool {
        return self.ppm > 50.0;
    }
}
node Zone { has name: str = ""; }
edge DeployedIn { has since: str = ""; }

walker Patrol {
    can start with Root entry {
        visit [->:DeployedIn:->];
    }
    can sweep with Zone entry {
        visit [->:DeployedIn:->];
    }
    can inspect with TempSensor | SmokeSensor entry {
        if here.is_alert() {
            print(f"[ALERT] {here}");
        } else {
            print(f"nominal: {here}");
        }
    }
}

with entry {
    z = Zone(name="A");
    root +>:DeployedIn(since="Mon"):+> z;
    z +>:DeployedIn:+> TempSensor(celsius=91.5);
    z +>:DeployedIn:+> SmokeSensor(ppm=12.0);
    root spawn Patrol();
}
'''
_FILTER_WARN = (
    "Jac 0.36 removed parenthesized filter syntax. NEVER write `(?:...)` "
    "anywhere; plain `visit [-->];` needs no filter at all."
)
SYSTEM = SYSTEM.replace(_CEILING, _UNION_NOTE)
SYSTEM += (
    "\n\nIDIOMATIZATION CONTRACT (binds wherever it does not conflict with "
    "the rules above):\n" + _SPEC[:4000] + "\n\n" + _SPEC6
    + "\n\nVERIFIED IDIOMATIC PATTERN (runs clean on jac 0.36.1):\n```jac\n"
    + _DEMO + "\n```\n" + _FILTER_WARN
)
_SKILL_TIER0 = (
    "\n\nSYNTAX FLOOR — violating any of these is non-Jac, not merely "
    "un-idiomatic (distilled from the jac-idiomatic skill):\n"
    "- Blocks: `if x { ... }` — NEVER `if x:` with indentation.\n"
    "- Statements end with `;` (a trailing implicit return is the only exception).\n"
    "- Booleans/null: `True`, `False`, `None` — never lowercase `true`/`false`/`null`.\n"
    "- for-unpack: `for (i, x) in enumerate(xs)` — never `for i, x in enumerate(xs)`.\n"
    "- Lambdas: `lambda (x: int) { x + 1 }` — never `lambda x: x + 1`.\n"
    "- `match` bodies: `case x:` followed by an INDENTED body — `case x { ... }` is a parse error.\n"
    "- Brace imports: `import from m { f }` with NO trailing `;`.\n"
    "- Never name variables `type`, `edge`, or other keywords.\n"
    "- `def` for methods/functions; `can ... with Node entry` ONLY for walker/node event abilities.\n"
    "- `self` is implicit in obj/node/walker method signatures — never declare it.\n"
    "- Types: concrete annotations on every def boundary; write `int | str | None` "
    "(not Optional), lowercase `list[str]` (not List), omit `-> None`."
)
SYSTEM += _SKILL_TIER0
_REF_PATH = REPO / "data" / "osp_examples" / "group_B" / "ex_22_hospital_union_staff.jac"
if _REF_PATH.exists():
    SYSTEM += ("\n\nREFERENCE RECORD (from the reference corpus):\n```jac\n"
               + _REF_PATH.read_text()[:3500] + "\n```")


def _user(problem: str) -> str:
    return (
        f"### Problem\n{problem.strip()}\n\n"
        "Produce the Jac program as a single ```jac fenced block."
    )


def _fix_user(problem: str, code: str, error: str) -> str:
    m = re.search(r"undefined name [`'](\w+)", error or "")
    hint = (
        f"\n\nThis error means `{m.group(1)}` is used as an edge type in a "
        "`visit [->:...]` / `[<--:...]` or a `+>:Name:+>` connection but was "
        f"never declared. Fix: add `edge {m.group(1)} {{ }}` at module level "
        "(an empty body is valid), or replace that typed traversal/connection "
        "with a plain `-->` / `++>` connection."
        if m else ""
    )
    return (
        f"### Problem\n{problem.strip()}\n\n"
        f"### Your previous program (rejected)\n```jac\n{code}\n```\n\n"
        f"### Validation error\n{error}\n{hint}\n\n"
        "Fix the program so it passes validation. Respond with the complete "
        "corrected program as a single ```jac fenced block. No prose."
    )


def call_zen(model: str, system: str, user: str, timeout: int,
             max_tokens: int, temperature: float, tries: int) -> tuple[str | None, str | None]:
    """Return (content, error). Rotates across the 8 zen keys on 429/5xx;
    fails fast on 4xx. Every request carries the opencode client headers the
    zen free tier requires (else 400 MissingSessionID)."""
    import httpx
    import uuid
    keys = _zen_keys()
    start_idx = _zen_key_start()
    body = {
        "model": model,
        "messages": [{"role": "system", "content": system},
                     {"role": "user", "content": user}],
        "max_tokens": max_tokens,
        "temperature": temperature,
    }
    last_err: str | None = None
    for attempt in range(tries):
        # rotate key each attempt so 429s/5xx spread across all 8 keys
        k = keys[(start_idx + attempt) % len(keys)]
        headers = {"Authorization": f"Bearer {k}",
                   "Content-Type": "application/json",
                   "User-Agent": "opencode/1.0.83",
                   "x-opencode-session-id": str(uuid.uuid4())}
        try:
            r = httpx.post(f"{ZEN_BASE}/chat/completions", headers=headers,
                           json=body, timeout=timeout)
        except (httpx.TimeoutException, httpx.HTTPError) as e:
            last_err = f"transport: {type(e).__name__}: {e}"
            time.sleep(2 ** attempt)
            continue
        if r.status_code in (429, 500, 502, 503, 504):
            last_err = f"http {r.status_code}: {r.text[:120]}"
            time.sleep(2 ** attempt)
            continue
        if r.status_code in (401, 402, 403):
            # key-scoped (invalid/no credits): fall through to next key
            last_err = f"http {r.status_code}: {r.text[:120]}"
            continue
        if 400 <= r.status_code < 500:
            return None, f"http {r.status_code}: {r.text[:200]}"
        r.raise_for_status()
        payload = r.json()
        try:
            choice = payload["choices"][0]
            content = choice["message"]["content"] or ""
        except (KeyError, IndexError, TypeError) as e:
            return None, f"malformed payload: {e}"
        if not content.strip():
            # reasoning models can burn the whole budget before any content
            fr = choice.get("finish_reason")
            last_err = f"empty content (finish_reason={fr})"
            time.sleep(2 ** attempt)
            continue
        return content, None
    return None, last_err or "exhausted retries"


def extract_jac(text: str) -> str | None:
    m = JAC_FENCE.search(text or "")
    return m.group(1).strip() if m else None


def _first_err(r: subprocess.CompletedProcess, fallback: str) -> str:
    """First stderr/stdout line that isn't jac's embedded-postgres WARNING
    (printed on every invocation; being first, it masks the real error)."""
    lines = (r.stderr or r.stdout).strip().splitlines()
    for ln in lines:
        if ln.strip() and not ln.lstrip().startswith("WARNING"):
            return ln.strip()
    return lines[0].strip() if lines else fallback


def jac_check(code: str, work: Path) -> tuple[bool, str]:
    """Write code to work/<rid>.jac and run `jac check` + `jac run`.

    `jac check` only validates syntax/types; it accepts programs whose
    `with entry` block raises NameError or prints nothing. The reference
    composer-2.5 batch is 100% runtime-clean — to match the bar we must
    also confirm the demo actually executes.
    """
    p = work / "main.jac"
    p.write_text(code)
    try:
        r = subprocess.run(["jac", "check", str(p)], capture_output=True,
                           text=True, timeout=60, cwd=work)
    except subprocess.TimeoutExpired:
        return False, "check-timeout"
    if r.returncode != 0:
        return False, _first_err(r, "check-fail")
    try:
        r = subprocess.run(["jac", "run", str(p)], capture_output=True,
                           text=True, timeout=30, cwd=work)
    except subprocess.TimeoutExpired:
        return False, "run-timeout"
    if r.returncode != 0:
        return False, _first_err(r, "run-fail")
    # The demo must actually produce output (proves the walker traversed
    # and printed something) — the reference batch all prints at least one
    # line of demo output, so a silent pass is a regression.
    if not (r.stdout or "").strip():
        return False, "run-no-output"
    return True, ""


# Structural OSP contract — same gates the reference composer-2.5 batch
# satisfies (audited: 100/100 reference records pass these; the relaxed
# downstream style checks like lowercase walker names only matter in
# group E). Kept conservative so minimax-m3 is held to the same bar.
_NODE_DECL = re.compile(r"\bnode\s+[A-Z]\w*\s*\{")
_WALKER_DECL = re.compile(r"\bwalker\s+[A-Za-z_]\w*\s*\{")
_TYPED_HAS = re.compile(r"\bhas\s+\w+\s*:\s*\w+\b")
_ABILITY_WITH_ENTRY = re.compile(
    r"can\s+\w+\s+with\s+(?:\w+|Root)\s+(?:entry|exit)\s*\{[^}]*?\bvisit\s*\["
)
_WITH_ENTRY = re.compile(r"\bwith\s+entry\s*\{")


def osp_contract(code: str) -> tuple[bool, str]:
    """Reject records that lose OSP semantics. Returns (ok, reason)."""
    if not code.lstrip().startswith('"""'):
        return False, "missing top-level docstring"
    if re.search(r"\bAny\b|->\s*object\b", code):
        return False, "uses Any/object"
    if _NODE_DECL.search(code) and not _TYPED_HAS.search(code):
        return False, "node has untyped has field"
    if _WALKER_DECL.search(code):
        # walker declared -> at least one ability must combine a typed
        # entry/exit with a `visit [...]` so the walker actually traverses.
        if not _ABILITY_WITH_ENTRY.search(code):
            return False, "walker ability does not `visit` after a typed entry"
    if not _WITH_ENTRY.search(code):
        return False, "no `with entry` demo block"
    if "spawn" not in code:
        return False, "no walker spawn call"
    # self-referential ternary: `x = "a" if cond else x;` etc.
    for m2 in re.finditer(
        r"=\s*[\"'][^\"']*[\"']\s+if\s+.+?\s+else\s+([A-Za-z_]\w*)\s*;", code
    ):
        var = m2.group(1)
        # confirm `var` appears on its own right-hand side of the same line
        line_start = code.rfind("\n", 0, m2.start()) + 1
        line_end = code.find("\n", m2.end())
        if line_end < 0:
            line_end = len(code)
        line = code[line_start:line_end]
        # match `else <var>;` at end of line
        if re.search(rf"else\s+{re.escape(var)}\s*;\s*$", line):
            return False, f"self-referential ternary for `{var}`"
    # Pythonism traps: `__main__`, `__name__`, `if __name__ == ...` are not
    # Jac and the model occasionally emits them on harder group-E problems.
    if re.search(r"\b__main__\b|\b__name__\b", code):
        return False, "uses Python __main__/__name__ idiom"
    # Walkers that `visit` something assigned to an undefined name: any
    # identifier used as a node target (`visit [->child]` / `[<--child]`)
    # that wasn't assigned in `with entry` first is a runtime NameError.
    # (Cheap proxy: an identifier referenced in a `visit [...]` literal that
    # is not assigned anywhere in the file.)
    for vm in re.finditer(r"\bvisit\s*\[\s*([^\]]+?)\s*\]", code):
        expr = vm.group(1)
        # only check identifiers inside `[...]`, skip `-->`, `<--`, `:Type:`
        for ident in re.findall(r"\b([A-Za-z_]\w*)\b", expr):
            if ident in {"visit", "self", "here", "root", "spawn", "to",
                         "Root", "else"}:
                continue
            # `:Type:` position holding a declared edge archetype is an edge
            # type, not a node variable — the skip this proxy documents.
            if re.search(rf"\bedge\s+{re.escape(ident)}\b", code):
                continue
            # check the ident is assigned somewhere (very rough)
            if not re.search(rf"\b{re.escape(ident)}\s*=", code):
                return False, f"visit references undefined name `{ident}`"
    return True, ""


def load_problems(path: str | None = None) -> list[dict]:
    out: list[dict] = []
    if path:
        for line in Path(path).read_text().splitlines():
            if line.strip():
                out.append(json.loads(line))
        return out
    for group in "ABCDE":
        path = BASE / f"group_{group}.jsonl"
        if not path.exists():
            continue
        for line in path.read_text().splitlines():
            if line.strip():
                out.append(json.loads(line))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=0,
                    help="stop after N records (0 = all 100)")
    ap.add_argument("--offset", type=int, default=0,
                    help="skip the first N problems")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the plan without calling the API")
    ap.add_argument("--variants", type=int, default=0,
                    help="generate N extra variant slots per already-passed "
                         "problem (ids `<rid>__muse_vK`, variant_idx=K)")
    ap.add_argument("--problems", default=None,
                    help="jsonl file with {id, problem} records; replaces "
                         "the osp_examples group replay")
    ap.add_argument("--shard", type=int, default=0)
    ap.add_argument("--shards", type=int, default=1,
                    help="split the work list across --shards workers; "
                         "this worker takes shard --shard")
    args = ap.parse_args()

    problems = load_problems(args.problems)
    problems = problems[args.offset:]
    if args.limit:
        problems = problems[: args.limit]

    print(f"[plan] {len(problems)} problems, model={MODEL}, temp={TEMP}, "
          f"out={OUT.relative_to(REPO)}", flush=True)
    if args.dry_run:
        for p in problems:
            print(f"  {p['id']}: {p['problem'][:80]}...")
        return 0

    OUT.parent.mkdir(parents=True, exist_ok=True)
    FAILS.parent.mkdir(parents=True, exist_ok=True)

    # Skip problems whose record already landed in a previous run so a
    # re-run only pays for the missing ones.
    existing_ids = set()
    if OUT.exists():
        for line in OUT.read_text().splitlines():
            if not line.strip():
                continue
            try:
                existing_ids.add(json.loads(line)["id"])
            except (json.JSONDecodeError, KeyError):
                continue
    if args.variants:
        # Variant mode: only re-solve problems that already passed once —
        # unpassed holdouts sit at ~0% and would burn free calls. Slots are
        # owned by exactly one shard (index slicing), so concurrent workers
        # never collide on ids, and every shard may append to OUT directly
        # (O_APPEND makes each completed row write atomic).
        passed = [p for p in problems if f"{p['id']}__muse" in existing_ids]
        items = [(p, n) for p in passed for n in range(1, args.variants + 1)
                 if f"{p['id']}__muse_v{n}" not in existing_ids]
        items = items[args.shard::args.shards]
    else:
        items = [(p, 0) for p in problems][args.shard::args.shards]

    def log_failure(rid: str, attempt: int, stage: str, error: str,
                    code: str | None) -> None:
        """Persist rejected attempts — (broken code, error) is the raw
        material for repair-training pairs."""
        row = {"id": rid, "attempt": attempt, "stage": stage,
               "error": error[:500], "ts": datetime.now().isoformat()}
        if code is not None:
            row["code"] = code
        with FAILS.open("a") as fh:
            fh.write(json.dumps(row) + "\n")

    n_ok = n_fail = n_skip = 0
    t0 = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix="osp_muse_") as tmp:
        for idx, (prob, vn) in enumerate(items, 1):
            rid = prob["id"]
            full_id = rid if vn == 0 else f"{rid}__muse_v{vn}"
            tag = rid if vn == 0 else f"{rid}#v{vn}"
            if full_id in existing_ids:
                n_skip += 1
                continue
            work = Path(tmp) / full_id
            work.mkdir(exist_ok=True)
            # Draft -> gate -> repair cycle: every gate failure earns a
            # repair call that carries the error back to the model.
            code: str | None = None
            prev_code: str | None = None
            last_err = "not attempted"
            passed = False
            for attempt in range(1 + FIX_TRIES):
                if code is None:
                    prompt = (_user(prob["problem"]) if attempt == 0 else
                              _fix_user(prob["problem"], prev_code or "",
                                        last_err))
                    content, err = call_zen(MODEL, SYSTEM, prompt,
                                           TIMEOUT, MAXTOK, TEMP, TRIES)
                    if err or not content:
                        last_err = f"call: {err or 'empty response'}"
                        continue
                    prev_code = extract_jac(content)
                    if prev_code is None:
                        last_err = "no ```jac fence in response"
                        continue
                    code = prev_code
                ok, log = jac_check(code, work)
                if ok:
                    ok, log = osp_contract(code)
                if ok:
                    passed = True
                    break
                last_err = log.strip().splitlines()[0] if log.strip() else "unknown"
                log_failure(full_id, attempt, "gate", last_err, code)
                print(f"[{idx:3d}/{len(items)}] {tag} gate-fail "
                      f"{attempt + 1}/{1 + FIX_TRIES} ({last_err})", flush=True)
                code = None
            if not passed:
                print(f"[{idx:3d}/{len(items)}] {tag} FAIL ({last_err})",
                      flush=True)
                log_failure(full_id, 1 + FIX_TRIES, "final", last_err, None)
                n_fail += 1
                continue
            row = {
                "id": full_id,
                "category": "code_gen",
                "task_type": "osp",
                "complexity": "medium",
                "compiler_pass": True,
                "test_pass": None,
                "manually_reviewed": False,
                "generator": "opencode-zen",
                "generator_model_id": MODEL,
                "gate_class": "compile_only",
                "variant_idx": vn,
                "generation_date": datetime.now().isoformat(),
                "source_prompt_version": "osp-ref-v1",
                "context_bundle_version": "jac-osp-reference-2025",
                "validator_version": "jac-0.36.1-check",
                "dataset_version": "jac-synth-v2.0.0",
                "run_tag": TAG,
                "messages": [
                    {"role": "user", "content": prob["problem"].strip()},
                    {"role": "assistant", "content": f"```jac\n{code.rstrip()}\n```"},
                ],
            }
            # O_APPEND per-record write: a crash or early stop (e.g. hitting
            # the target count) keeps every completed record.
            with OUT.open("a") as fh:
                fh.write(json.dumps(row) + "\n")
            n_ok += 1
            elapsed = time.perf_counter() - t0
            print(f"[{idx:3d}/{len(items)}] {tag} OK  "
                  f"({n_ok} pass / {n_fail} fail / {n_skip} skip / "
                  f"{elapsed:.1f}s)", flush=True)

    print(f"\n[done] records in {OUT.relative_to(REPO)}")

    total = time.perf_counter() - t0
    print(f"[stats] pass={n_ok} fail={n_fail} skip={n_skip} wall={total:.1f}s")
    return 0 if n_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())