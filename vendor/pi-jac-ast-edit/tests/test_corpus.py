"""Edits over a sample of real Jac files (dry run, nothing written).

Corpus: $JAC_CORPUS_DIR (default ~/repos/jaseci/jac), skipped when missing.
Sample size: $JAC_CORPUS_SAMPLE files (default 60), fixed seed.
"""
from __future__ import annotations

import os
import random
from pathlib import Path

import pytest

from conftest import engine

CORPUS = Path(os.environ.get("JAC_CORPUS_DIR", Path.home() / "repos" / "jaseci" / "jac"))
SAMPLE = int(os.environ.get("JAC_CORPUS_SAMPLE", "60"))

pytestmark = pytest.mark.skipif(not CORPUS.is_dir(), reason=f"no Jac corpus at {CORPUS}")


def sample_files() -> list[Path]:
    files = sorted(CORPUS.rglob("*.jac"))
    random.Random(0).shuffle(files)
    out = []
    for f in files:
        try:
            src = f.read_bytes()
        except OSError:
            continue
        # only files the grammar parses cleanly: the gate rejects edits next to
        # pre-existing parse errors by design
        if len(src) < 200_000 and not engine.new_parser().parse(src).root_node.has_error:
            out.append(f)
        if len(out) >= SAMPLE:
            break
    return out


def outcome(path: Path, op: dict) -> str:
    try:
        res = engine.apply_batch(path, [op], dry_run=True)
    except engine.EditError as e:
        return e.code
    after = engine.new_parser().parse(res["_source"]).root_node
    return "ok" if not after.has_error else "parse_error_written"


def test_corpus_edits_keep_files_parseable():
    files = sample_files()
    assert files, "corpus has no cleanly parsing files"
    counts: dict[str, int] = {}
    for f in files:
        src = f.read_bytes()
        for s in engine._index_symbols(engine.new_parser().parse(src).root_node)[:10]:
            name = s.qualified or s.name
            if s.kind in ("function", "ability", "impl", "test") and name and engine._brace_span(s.node):
                ob, cb = engine._brace_span(s.node)
                body = src[ob.end_byte:cb.start_byte].decode("utf-8", "replace")
                ops = {"set_body_same": {"action": "set_body", "target": s.kind, "name": name, "newCode": body},
                       "add_statement": {"action": "add_statement", "target": s.kind, "name": name,
                                         "newCode": "if x {\n    y = 1;\n}"}}
            elif s.kind in engine.ARCHETYPE_KINDS and s.name:
                ops = {"add_member": {"action": "add_member", "target": s.kind, "name": s.name,
                                      "newCode": "def zz() -> int {\n    return 1;\n}"}}
            else:
                continue
            for label, op in ops.items():
                if op["action"] == "set_body" and not op["newCode"].strip():
                    continue
                key = f"{label}:{outcome(f, op)}"
                counts[key] = counts.get(key, 0) + 1
    print(sorted(counts.items()))
    assert not any(k.endswith("parse_error_written") for k in counts), counts
    for label in ("set_body_same", "add_statement", "add_member"):
        ok = counts.get(f"{label}:ok", 0)
        total = sum(v for k, v in counts.items() if k.startswith(label + ":"))
        # duplicate names (ambiguous_symbol) are the only accepted failures
        bad = {k: v for k, v in counts.items() if k.startswith(label + ":")
               and not k.endswith((":ok", ":ambiguous_symbol"))}
        assert total == 0 or ok / total >= 0.95, (label, counts)
        assert not bad, bad
