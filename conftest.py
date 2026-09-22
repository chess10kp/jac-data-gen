"""Repo-root pytest guard.

Running `jac test <scratch>.jac` (or pytest) from the repo root lets jac and
the code under test write into the root: `.pytest_cache/`, `.jac/` caches,
`save_file()` outputs, bytecode dumps — this is where the root junk of
2026-08 came from. Two defenses:

1. `_sandbox_cwd` runs every test with cwd inside pytest's tmp area, so
   tested code cannot drop files into the root.
2. `pytest_sessionfinish` sweeps the known machine-dropping patterns
   (mirroring the .gitignore root-junk list) into the cold archive —
   covering droppers outside our control (IDE debugger test runs etc).

Suites that manage their own cwd are unaffected: `jaseci/jac` is invoked
from its own directory (its rootdir stops conftest discovery above it), and
the `scripts/` test files are tmp_path-based and never read the old cwd.
"""
import shutil
import time
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent
JUNK_FILES = [
    "C:*", "False", "True", "str_file_path", "nohup.out",
    "bc.dyn", "my_bc.dyn", "_format_data_as_table_temp.jac",
    "test_save_file_pass.py",
    "last_known_id_*.txt",
    "a.txt", "b.txt", "foo.txt", "sample.txt", "example.txt", "tmp.txt",
    "test.txt", "test_file.txt", "test_output.txt", "temp_file_1.txt",
    "test_save_file.txt", "unit_test.txt", "analogies.txt", "analogy_test.txt",
]
JUNK_DIRS = ["a", ".foo"]


@pytest.fixture(autouse=True)
def _sandbox_cwd(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)


def pytest_sessionfinish(session, exitstatus):
    hits = [p for pat in JUNK_FILES for p in ROOT.glob(pat) if p.is_file()]
    hits += [d for name in JUNK_DIRS if (d := ROOT / name).is_dir()]
    if not hits:
        return
    dest = ROOT / "archive" / "2026-09" / "root_scratch" / time.strftime("auto-%Y%m%d-%H%M%S")
    dest.mkdir(parents=True, exist_ok=True)
    for p in hits:
        target = dest / p.name
        shutil.move(str(p), str(target))  # moves dirs wholesale on name clash-free paths
    print(f"\n[conftest] swept {len(hits)} root litter item(s) -> {dest.relative_to(ROOT)}")
