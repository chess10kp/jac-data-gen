#!/usr/bin/env python3
"""Reference harness for iss_keboola__agnes-the-ai-analyst__677.py"""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_keboola__agnes-the-ai-analyst__677.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
assert spec.loader is not None
spec.loader.exec_module(mod)


def main() -> None:
    g = mod.EntityGraph()
    g.mention("pdf", "Acme")
    g.mention("pdf", "Widget")
    g.mention("crm", "Acme")
    g.mention("crm", "Revenue")
    g.mention("contract", "Widget")
    g.mention("contract", "Revenue")
    assert g.linked_entities("Acme", 1) == ["Revenue", "Widget"]
    assert g.bridge("Acme", "Revenue") == ["Acme", "Revenue"]
    assert g.linked_entities("missing", 2) == []
    assert g.bridge("Acme", "missing") is None

    g2 = mod.EntityGraph()
    g2.mention("doc_right", "right")
    g2.mention("doc_right", "cap")
    g2.mention("doc_left", "left")
    g2.mention("doc_left", "cap")
    g2.mention("doc_hub", "seed")
    g2.mention("doc_hub", "left")
    g2.mention("doc_hub", "right")
    assert g2.linked_entities("seed", 2) == ["cap", "left", "right"]

    g3 = mod.EntityGraph()
    g3.mention("d1", "a")
    g3.mention("d1", "b")
    g3.mention("d2", "b")
    g3.mention("d2", "c")
    g3.mention("d3", "c")
    g3.mention("d3", "a")
    g3.mention("d4", "b")
    g3.mention("d4", "d")
    assert g3.linked_entities("a", 5) == ["b", "c", "d"]

    g4 = mod.EntityGraph()
    g4.mention("only", "solo")
    assert g4.linked_entities("solo", 0) == []
    assert g4.bridge("solo", "solo") == ["solo"]
    assert g4.bridge("solo", "nope") is None

    print("ok")


if __name__ == "__main__":
    main()
