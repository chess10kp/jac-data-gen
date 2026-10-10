"""Shared helpers: import the engine from ../python and run edits on copies
of tests/fixtures/sample.jac. The post-edit `jac check` is off unless a test
turns it on (tests/test_check.py)."""
from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "python"))

import jac_ast_edit as engine  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / "fixtures"
SAMPLE = (FIXTURES / "sample.jac").read_text()


@pytest.fixture(autouse=True)
def _isolate(monkeypatch, tmp_path):
    monkeypatch.setenv("JAC_AST_EDIT_CHECK", "0")
    monkeypatch.setenv("JAC_AST_EDIT_CACHE_DIR", str(tmp_path / "cache"))


@pytest.fixture
def jac_file(tmp_path):
    """Factory: write source (default: the sample) to tmp and return its path."""
    def make(src: str = SAMPLE, name: str = "f.jac") -> Path:
        p = tmp_path / name
        p.write_text(src)
        return p
    return make


def edit(path: Path, *ops: dict, **payload) -> dict:
    """Run one batch through the engine entry point; returns the result dict
    (with `report`). Raises engine.EditError on rejection."""
    return engine.cmd_edit(path, {"operations": list(ops), "displayPath": path.name, **payload})
