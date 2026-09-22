"""Guard: every jac subprocess spawn in scripts/ must pin a sandbox cwd.

jac and the code it runs write `.pytest_cache/`, `.jac/`, save_file() outputs
into the inherited CWD — the root-litter regression class of 2026-08/09.
The check itself lives in scripts/ops/check_jac_cwd.py.
"""
import subprocess
import sys
from pathlib import Path

CHECKER = Path(__file__).resolve().parents[1] / "ops" / "check_jac_cwd.py"


def test_no_unsandboxed_jac_spawns():
    r = subprocess.run(
        [sys.executable, str(CHECKER)], capture_output=True, text=True, timeout=120
    )
    assert r.returncode == 0, r.stdout + r.stderr
