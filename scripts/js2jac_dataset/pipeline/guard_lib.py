"""Shared guard primitives for the js2jac pipeline: `jac check` with an
address-space cap + result cache, ORM hollowness/behavioral rejection, and
work-meta loading. Imported by the chunk.sh guard stage and by
dpo_backfill.py so the verdict logic exists in exactly one place.

Extracted verbatim from the chunk.sh guard heredoc when DPO backfill needed
the same logic; behavior is unchanged.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

DEFAULT_JAC_REPO = "/home/jac/repos/jac_llm_data/jaseci/jac"
# 3GB address-space cap per jac check — same fix as step4_full_loop._run
# (Aug 20 OOM freezes). A runaway check dies as a compile-fail instead.
AS_CAP = int(os.environ.get("JAC_RLIMIT_AS_GB", "3")) << 30

# Run the CHECKOUT's own jac (0.35.x, js2jac branch) via `python -m jaclang`
# — never the ambient `jac` binary. The ambient install (0.36.1, frozen,
# Aug 31) bootstraps via jaclang.cli.cli_boot, which the checkout predates:
# from cwd=jac_repo the checkout shadows it and every invocation dies with
# ModuleNotFoundError (silently, sometimes exit 0); from a neutral cwd it
# runs but lacks the js2jac tool entirely. `python -m jaclang` from the
# checkout root is the only invocation that is both alive and tool-complete,
# and it pins the pipeline to ONE compiler generation (the branch's).
# js2jac also needs the bun runtime (JAC_BUN); the frozen install bundles it,
# the source tree does not.
JAC_BUN = os.environ.get("JAC_BUN", "/usr/sbin/bun")


def jac_argv(*args: str) -> list[str]:
    """Full argv to run the checkout's jac: [<venv python>, -m, jaclang, ...].
    Run with cwd=DEFAULT_JAC_REPO (import resolution) and merge JAC_ENV()."""
    return [sys.executable, "-m", "jaclang", *args]


def jac_env() -> dict[str, str]:
    return {"JAC_BUN": JAC_BUN}

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "gates"))
from orm_behavioral_gate import gate_orm  # noqa: E402

_GRAPH_OP = re.compile(r"-->|\+\+>|\bspawn\b|\+>:|->:|<-:|:->|:<-|\[\?:|\bdel here\b|\bhere\.|\bjobj\(")


class Checker:
    """`jac check` subprocess wrapper: prlimit AS cap, 90s timeout, code cache."""

    def __init__(self, jac_repo: str = DEFAULT_JAC_REPO):
        self.jac_repo = jac_repo
        self._ok: dict[str, bool] = {}

    def ok(self, code: str | None) -> bool:
        if not code or code == "REJECT":
            return False
        if code not in self._ok:
            with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False) as tf:
                tf.write(code)
                tp = tf.name
            try:
                # cwd=jac_repo + `python -m jaclang`: runs the CHECKOUT's jac
                # (see the jac_argv note above). The old ambient-binary +
                # neutral-cwd dance is gone — one compiler for convert+gate.
                self._ok[code] = subprocess.run(
                    ["prlimit", f"--as={AS_CAP}", "--", *jac_argv("check", tp)],
                    cwd=self.jac_repo, capture_output=True, timeout=90,
                    env={**os.environ, **jac_env()},
                ).returncode == 0
            except Exception:
                self._ok[code] = False
            finally:
                os.unlink(tp)
        return self._ok[code]


def hollow(m: dict, code: str) -> bool:
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


def orm_reject(m: dict, code: str, ck: Checker) -> tuple[bool, str]:
    # For ORM records: prefer the BEHAVIORAL gate (seed->invoke->assert read-back)
    # over the structural one — it catches wrong-filter/wrong-edge rewrites that
    # DO touch the graph (so pass `hollow`) but read back nothing real. Only when
    # the gate can't build a probe (no scalar entrypoint) fall back to structural.
    schema = m.get("schema_jac")
    if not schema:
        return False, "not-orm"
    verdict, why = gate_orm(schema, code, ck.jac_repo)
    if verdict == "KEEP":
        return False, f"behavioral:{why}"
    if verdict == "REJECT":
        return True, f"behavioral:{why}"
    return hollow(m, code), f"structural-fallback:{why}"   # INCONCLUSIVE


def load_meta(work_dir: str | Path) -> dict[str, dict]:
    """id -> work record (source_js, floor_jac, schema_jac, ...) for a run."""
    meta: dict[str, dict] = {}
    for f in Path(work_dir).glob("*.json"):
        if f.name == "report.json":
            continue
        r = json.loads(f.read_text())
        meta[r["id"]] = r
    return meta


def load_repair_meta(run_dir: str | Path) -> dict[str, dict]:
    """id -> {floor_jac, source_js} from repair work items (floors survive
    there even after a run's work/ dir is gone, e.g. js2jac_0)."""
    meta: dict[str, dict] = {}
    rdir = Path(run_dir) / "repair_work"
    for f in sorted(rdir.glob("*.json")):
        w = json.loads(f.read_text())
        if w.get("id") and w.get("floor_jac"):
            meta[w["id"]] = {"floor_jac": w["floor_jac"], "source_js": w.get("source_js")}
    return meta


def jsonl(path: str | Path) -> list[dict]:
    """Tolerant jsonl reader: skips blank and crash-truncated lines (seen in
    archive candidates.jsonl tails)."""
    out: list[dict] = []
    try:
        fh = open(path)
    except FileNotFoundError:
        return out
    with fh:
        for line in fh:
            if not line.strip():
                continue
            try:
                out.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return out
