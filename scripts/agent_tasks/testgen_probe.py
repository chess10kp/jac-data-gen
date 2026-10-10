#!/usr/bin/env python3
"""One-off CI probe: how to keep a jac 0.36.1 test module off the native codespace."""
import json, shutil, subprocess, sys, tempfile
from pathlib import Path
REPO = Path(__file__).resolve().parents[2]
T = REPO / "data/agent_tasks/testgen/tg-l1-password-rules"
out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
suite = (T / "grader/reference/passcheck_tests.jac").read_text()
variants = {
    "asis": (suite, None),
    "heapq": ("import heapq;\n" + suite, None),
    "sys": ("import sys;\n" + suite, None),
    "toml_server": (suite, '[build]\ndefault_codespace = "server"\n'),
    "toml_project_server": (suite, '[project]\nname = "p"\n\n[build]\ndefault_codespace = "server"\n'),
}
res = {}
for name, (src, toml) in variants.items():
    d = Path(tempfile.mkdtemp())
    shutil.copy(T / "starter/passcheck.jac", d)
    (d / "passcheck_tests.jac").write_text(src)
    if toml:
        (d / "jac.toml").write_text(toml)
    p = subprocess.run(["jac", "test", "passcheck_tests.jac"], cwd=d, capture_output=True, text=True, timeout=300)
    o = p.stdout + p.stderr
    res[name] = {"rc": p.returncode, "tail": o[-700:], "native": "invoke_native_test" in o}
    print(name, p.returncode, o.strip().splitlines()[-1] if o.strip() else "")
(out / "probe.json").write_text(json.dumps(res, indent=1))
