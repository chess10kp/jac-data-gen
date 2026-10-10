#!/usr/bin/env python3
"""Mass-produce `app` agent tasks (spec + reference + hidden checks) with an LLM.

DRAFT. The 25-task pilot under data/agent_tasks/app/ was hand-authored and
hand-checked; this script scales the same recipe and routes every generated task
through the SAME validator (scripts/agent_tasks/app_build.py), so nothing reaches
the manifest as validated unless the reference passes all gates, the bare starter
fails, and the request clears eval dedup.

Pipeline per task:
  1. pick (level, domain): domains come from --domains file or an LLM brainstorm,
     filtered against the eval app ideas (app_build.FRONTEND_DOMAINS) and against
     domains already in the pool (no near-duplicate pilots).
  2. LLM call -> one JSON object: request_md, target_paths, reference files,
     tests_jac, checks_py (body of grader/smoke.py or behavioral.py: a
     `def checks(srv|cli)` using the shared helpers). The prompt carries:
     the level contract, a full pilot exemplar of the same level (few-shot),
     verified Jac idioms/quirks, and the design-tolerance rules for checks.
  3. write data/agent_tasks/app/<id>/ (starter copied from a pilot of the same
     level; grader script = shared harness head from that pilot + checks_py).
  4. cheap local pre-gates: schema, dedup, `jac check` of the reference (one at a
     time); failures get --repair rounds that feed the diagnostics back.
  5. full validation is app_build.py's job (run on CI via .ci/agent-tasks/app.sh);
     tasks it rejects stay in the dir with validated:false in the manifest.

Usage:
  app_specgen.py --level 3 --n 10 --backend openrouter --model <model> [--domains file.txt]
  app_specgen.py --level 5 --n 5 --dry-run          # print the prompt only
"""
from __future__ import annotations

import argparse
import json
import random
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(REPO / "scripts" / "lib"))
import app_build as B  # noqa: E402

GATES = {1: ["check", "test"], 2: ["check", "test"], 3: ["check", "test", "run", "behavioral"],
         4: ["check", "test", "start", "behavioral"], 5: ["check", "test", "start", "behavioral"]}

LEVEL_CONTRACT = {
    1: "Function library: one module of plain `def`s / `obj`s. No nodes, walkers, HTTP or persistence.",
    2: "Graph model: `node`/`edge` archetypes (edges declare endpoints `edge E: A --> B {}`) and walkers "
       "spawned on a node that traverse with `visit` and report ONCE (accumulate, report in `with exit`). "
       "No persistence; hidden tests build transient graphs.",
    3: "OSP CLI with persistence: data as nodes under `root`, walkers spawned on `root` (named in the spec "
       "with their `has` fields), plus a CLI in `with entry:__main__` reading sys.argv "
       "(`jac run main.jac <cmd> ...`). State must persist across separate processes.",
    4: "Minimal service: exactly one public endpoint (`walker:pub X` -> POST /walker/X or `def:pub f` -> "
       "POST /function/f) in main.jac, persisted on root; the request asks the user's agent to add tests.",
    5: "Fullstack service: >=3 public endpoints (state each path), persisted graph under root, explicit "
       "error contract ({\"error\": ...}), tests requested; optionally a client UI (web-app kind).",
}

IDIOMS = """Verified jac 0.37.25 facts (use them, do not contradict them):
- Test blocks: `test "name" { assert ...; }`; `with testraises(ValueError) { ... }`.
- Hidden tests live in a separate module `import from <target_module> { names }`; never name files test_*.jac.
- `root` is a value (never `root()`); entry abilities `can x with Root entry`, `can y with Node entry`; generic
  `can done with exit` fires once after the whole traversal.
- `new = here ++> Item(...)` returns the node; typed edge `a +>:E(f=1):+> b`; traversal `[a ->:E:->]`,
  `[a <-:E:<-]`, edge objects `[edge a ->:E:-> b]`; delete typed edge `del [edge a ->:E:-> b];`.
- `has reports`-free walkers: `(root spawn W(f=1)).reports[0]`.
- A walker `has` field named like an imported module symbol SHADOWS it inside abilities (field `date` hides
  `datetime.date` imported as `date`) -> import the module (`import datetime;`) instead.
- Bare generic annotations are errors (E1036): write `list[str]`, `dict[str, any]`.
- A variable's first assignment pins its type: assigning two different walker types to one name is E1001.
- `[n -->[?:T, field == v]]` field predicates resolve to Unknown in some contexts (W1051); prefer a comprehension.
- `jac start` is gone: serve with `jac run --serve --port N main.jac`; envelopes are
  {"ok", "data": {"result", "reports"}, "error"}; walker reports are in data.reports, function returns in data.result.
- Persisted graph is keyed by cwd; hidden tests on root must use uuid-unique names and assert deltas only.
- Anchor-free modules (no Python import / root / pub) are compiled NATIVE. Under native-placed test modules an
  `any`-typed value compared to a list/dict literal is False (`r.reports[0] == ["a"]`): always compare
  `list(x) == [...]` / `dict(x) == {...}`.
- A native module with one un-lowerable ability (e.g. `[edge a ->:E:-> b]`) is demoted piecemeal and the mixed
  module SIGABRTs with no output; anchor such a module server with an import that has no native twin
  (`import heapq;` works; `sys`/`math`/`uuid` do not).
- `jac test` exits 0 with "N skipped" when the test module's import fails: never treat rc==0 as a pass.
"""

CHECK_RULES = """Rules for hidden checks (they will run against OTHER people's solutions):
- Test only what the request states explicitly: module/walker/function names, fields, endpoint paths, report
  shapes, CLI commands and output keywords. Never test internal helper names or node layouts unless stated.
- Accept reasonable alternatives: dict-or-node reports (`get(x, k)` helper), one list report vs one report per
  item (`flat`/`items` helpers), errors as {"error"} report / ok=false / 4xx (`is_error`), ids as `id` or `_jac_id`.
- Assert on deltas / unique names whenever state persists. Compare floats with a tolerance.
- The bare starter must FAIL the checks (no vacuous asserts). Do not mention tests or graders in request.md.
"""

SCHEMA = """Return ONE JSON object, no prose, no fences:
{"id_slug": "kebab-case-domain", "domain": "short domain phrase",
 "request_md": "...", "target_paths": ["main.jac"],
 "reference": {"<relative path>": "<file content>", ...},
 "tests_jac": "<grader/tests.jac content>",
 "checks_py": "<python: def checks(srv): ... for levels 4-5 / def checks(cli): ... for level 3; empty for 1-2>"}"""


def pilot_exemplar(level: int) -> Path:
    for d in B.load_tasks():
        meta = json.loads((d / "task.json").read_text())
        if meta["level"] == level and meta.get("source") == "hand-authored":
            return d
    raise SystemExit(f"no pilot task for level {level}")


def exemplar_text(d: Path) -> str:
    parts = [f"### request.md\n{(d / 'request.md').read_text()}"]
    for p in sorted((d / "grader" / "reference").rglob("*.jac")):
        parts.append(f"### reference/{p.relative_to(d / 'grader' / 'reference')}\n{p.read_text()}")
    parts.append(f"### grader/tests.jac\n{(d / 'grader' / 'tests.jac').read_text()}")
    for name in ("smoke.py", "behavioral.py"):
        if (d / "grader" / name).exists():
            parts.append(f"### checks_py (body only)\n{split_harness(d / 'grader' / name)[1]}")
    return "\n\n".join(parts)


def split_harness(script: Path) -> tuple[str, str]:
    """Shared harness head (helpers + main) vs the task-specific `checks` body."""
    s = script.read_text()
    i = s.index("\ndef main():")
    j = s.index("\n\n\n", i) + 3
    tail = '\n\nif __name__ == "__main__":\n    main()\n'
    body = s[j:-len(tail)] if s.endswith(tail) else s[j:]
    return s[:j], body


def existing_domains() -> list[str]:
    return [json.loads((d / "task.json").read_text()).get("provenance", {}).get("domain", "")
            for d in B.load_tasks()]


def build_prompt(level: int, domain: str) -> tuple[str, str]:
    ex = pilot_exemplar(level)
    system = ("You author training tasks for a Jac coding agent: a realistic user request, a verified "
              "reference implementation in idiomatic Jac, and hidden behavioral checks.\n\n" + IDIOMS
              + "\n" + CHECK_RULES + "\n" + SCHEMA)
    user = (f"Level {level}: {LEVEL_CONTRACT[level]}\nDomain: {domain}\n"
            f"Vary tone (terse / detailed / bullet list) and do not copy the exemplar's domain.\n"
            f"Avoid these eval app ideas entirely: {', '.join(B.FRONTEND_DOMAINS)}.\n\n"
            f"Exemplar task of the same level (format and rigor to match):\n\n{exemplar_text(ex)}")
    return system, user


def parse_json(text: str) -> dict | None:
    m = re.search(r"\{.*\}", text or "", re.S)
    if not m:
        return None
    try:
        return json.loads(m.group(0))
    except ValueError:
        return None


def write_task(level: int, spec: dict, model: str) -> Path:
    slug = re.sub(r"[^a-z0-9-]+", "-", spec["id_slug"].lower()).strip("-")[:40]
    tid = f"app-l{level}-{slug}"
    d = B.TASKS / tid
    if d.exists():
        tid += f"-{random.randint(100, 999)}"
        d = B.TASKS / tid
    ex = pilot_exemplar(level)
    shutil.copytree(ex / "starter", d / "starter", ignore=shutil.ignore_patterns(".jac"))
    proj_old = ex.name.split("-", 2)[2].replace("-", "_")
    for p in (d / "starter").rglob("*"):
        if p.is_file():
            p.write_text(p.read_text().replace(proj_old, slug.replace("-", "_")))
    (d / "request.md").write_text(spec["request_md"].rstrip() + "\n")
    ref = d / "grader" / "reference"
    for rel, content in spec["reference"].items():
        if ".." in Path(rel).parts:
            continue
        (ref / rel).parent.mkdir(parents=True, exist_ok=True)
        (ref / rel).write_text(content)
    (d / "grader" / "tests.jac").write_text(spec["tests_jac"])
    if level >= 3:
        name = "smoke.py" if level >= 4 else "behavioral.py"
        head, _ = split_harness(ex / "grader" / name)
        (d / "grader" / name).write_text(head + spec["checks_py"].strip() + '\n\n\nif __name__ == "__main__":\n    main()\n')
    (d / "grader" / "notes.md").write_text(
        f"# {tid} (level {level})\n\nLLM-generated ({model}) from the pilot recipe; validated only if "
        f"manifest says so (app_build.py).\n\nDomain: {spec.get('domain', '')}\n")
    meta = {"id": tid, "kind": "app", "level": level, "source": f"llm:{model}", "gates": GATES[level],
            "target_paths": spec["target_paths"], "jac_version": B.JAC_VERSION, "license": "MIT",
            "provenance": {"domain": spec.get("domain", ""), "generator": "scripts/agent_tasks/app_specgen.py",
                           "exemplar": ex.name, "model": model}}
    (d / "task.json").write_text(json.dumps(meta, indent=2) + "\n")
    return d


def precheck(d: Path) -> str | None:
    """Cheap local gates: schema + dedup + `jac check` of the reference (single process)."""
    meta = json.loads((d / "task.json").read_text())
    errs = B.schema_errors(d, meta)
    if errs:
        return "; ".join(errs)
    dd = B.dedup(d)
    if not dd["pass"]:
        return f"dedup: {dd}"
    ws = B.stage(d, with_reference=True)
    shutil.copy(d / "grader" / "tests.jac", ws / B.HIDDEN_NAME)
    r = subprocess.run(["jac", "check", *meta["target_paths"], B.HIDDEN_NAME], cwd=ws,
                       capture_output=True, text=True, timeout=600)
    shutil.rmtree(ws, ignore_errors=True)
    return None if r.returncode == 0 else "jac check:\n" + B.tail(r.stdout + r.stderr, 60)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--level", type=int, required=True, choices=[1, 2, 3, 4, 5])
    ap.add_argument("--n", type=int, default=5)
    ap.add_argument("--domains", help="file with one domain per line (else LLM brainstorm)")
    ap.add_argument("--backend", default="auto")
    ap.add_argument("--model", default="openrouter:qwen/qwen3-coder")
    ap.add_argument("--repair", type=int, default=2, help="repair rounds on precheck failure")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    taken = [x.lower() for x in existing_domains()]
    if a.domains:
        pool = [l.strip() for l in Path(a.domains).read_text().splitlines() if l.strip()]
    else:
        pool = []
    pool = [p for p in pool if p.lower() not in taken
            and not any(re.search(rx, p.lower()) for rx in B.FRONTEND_DOMAINS.values())]

    if a.dry_run:
        s, u = build_prompt(a.level, pool[0] if pool else "<domain>")
        print(s, "\n\n=====\n\n", u)
        return

    from llm_backend import get_backend, strip_prefix  # noqa: E402
    backend = get_backend(a.backend, a.model)
    model = strip_prefix(a.model)
    if not pool:
        text, err, _ = backend.call("Reply with plain lines only.",
                                    f"List {a.n * 3} distinct small-business or hobby app domains suitable for "
                                    f"a level-{a.level} Jac task ({LEVEL_CONTRACT[a.level]}). One per line, "
                                    f"3-6 words, no numbering. Avoid: {', '.join(B.FRONTEND_DOMAINS)}, "
                                    f"{', '.join(taken)}.", model, 300)
        pool = [l.strip("-* ").strip() for l in (text or "").splitlines() if l.strip()]
        pool = [p for p in pool if not any(re.search(rx, p.lower()) for rx in B.FRONTEND_DOMAINS.values())]
    made = 0
    for domain in pool:
        if made >= a.n:
            break
        system, user = build_prompt(a.level, domain)
        spec = None
        for attempt in range(1 + a.repair):
            text, err, _ = backend.call(system, user, model, 900)
            spec = parse_json(text or "")
            if not spec:
                user += "\n\nYour previous reply was not a single valid JSON object. Return only the JSON."
                continue
            d = write_task(a.level, spec, model)
            why = precheck(d)
            if why is None:
                print(f"[ok] {d.name} (precheck green; run app_build.py validate for full gates)")
                made += 1
                break
            print(f"[retry {attempt}] {d.name}: {why.splitlines()[0]}")
            shutil.rmtree(d, ignore_errors=True)
            user += f"\n\nYour previous task failed a local check:\n{why}\nFix it and return the full JSON again."
    B.write_manifest()


if __name__ == "__main__":
    main()
