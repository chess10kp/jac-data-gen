#!/usr/bin/env python3
"""Pack the 100 OSP examples into a golden-style JSONL dataset.

Reads data/osp_examples/group_{A..E}.jsonl manifests, re-checks every .jac
file with `jac check`, and emits data/osp_dataset.jsonl with the same
message schema as golden_client.jsonl:
  messages[0].content = problem statement
  messages[1].content = ```jac ...``` fenced solution
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))
from jacresolve import resolve_jac  # noqa: E402

JAC = resolve_jac()
BASE = REPO / "data" / "osp_examples"
OUT = REPO / "data" / "osp_dataset.jsonl"


def jac_ok(path: Path) -> bool:
    r = subprocess.run([JAC, "check", str(path)], capture_output=True, text=True,
                       cwd=tempfile.gettempdir())
    return r.returncode == 0


def main() -> int:
    rows = []
    failures = []
    for group in ["A", "B", "C", "D", "E"]:
        manifest = BASE / f"group_{group}.jsonl"
        if not manifest.exists():
            print(f"MISSING manifest: {manifest}")
            failures.append(str(manifest))
            continue
        for line in manifest.read_text().splitlines():
            if not line.strip():
                continue
            rec = json.loads(line)
            src = BASE / rec["file"]
            if not src.exists():
                failures.append(rec["id"] + ": missing file " + str(src))
                continue
            if not jac_ok(src):
                failures.append(rec["id"] + ": jac check failed")
                continue
            code = src.read_text()
            if not code.startswith('"""'):
                failures.append(rec["id"] + ": no module docstring")
                continue
            rows.append({
                "id": rec["id"],
                "category": "code_gen",
                "task_type": "osp",
                "complexity": "medium",
                "compiler_pass": True,
                "test_pass": None,
                "manually_reviewed": False,
                "generator": "cursor-cli",
                "generator_model_id": "composer-2.5",
                "gate_class": "compile_only",
                "variant_idx": 0,
                "generation_date": datetime.now().isoformat(),
                "source_prompt_version": "osp-ref-v1",
                "context_bundle_version": "jac-osp-reference-2025",
                "validator_version": "jac-0.36.1-check",
                "dataset_version": "jac-synth-v2.0.0",
                "run_tag": "osp_100",
                "messages": [
                    {"role": "user", "content": rec["problem"].strip()},
                    {"role": "assistant", "content": f"```jac\n{code.rstrip()}\n```"},
                ],
            })

    OUT.write_text("".join(json.dumps(r) + "\n" for r in rows))
    print(f"wrote {len(rows)} records -> {OUT}")
    if failures:
        print(f"{len(failures)} FAILURES:")
        for f in failures:
            print(" -", f)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
