#!/usr/bin/env python3
"""Reference harness for iss_mjshuff23__prep__11.py"""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_mjshuff23__prep__11.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
spec.loader.exec_module(mod)


def _norm(xs: list[str]) -> list[str]:
    return sorted(xs)


def main() -> None:
    g = mod.PackGraph()

    # linear: graph -> heap -> trie
    g.add_pack("graph")
    g.link("graph", "heap")
    g.link("heap", "trie")
    assert _norm(g.descendants("graph")) == ["heap", "trie"]
    assert _norm(g.descendants("heap")) == ["trie"]
    assert _norm(g.descendants("trie")) == []
    assert _norm(g.descendants("missing")) == []

    # diamond: wave hub fans to two packs then merge
    g2 = mod.PackGraph()
    g2.link("wave", "array")
    g2.link("wave", "deque")
    g2.link("array", "shared")
    g2.link("deque", "shared")
    assert _norm(g2.descendants("wave")) == ["array", "deque", "shared"]

    # cycle: a->b->c->a plus d off b (revisit before deep first-visit)
    g3 = mod.PackGraph()
    g3.link("a", "b")
    g3.link("b", "c")
    g3.link("c", "a")
    g3.link("b", "d")
    assert _norm(g3.descendants("a")) == ["b", "c", "d"]

    # idempotent add
    g4 = mod.PackGraph()
    g4.add_pack("solo")
    g4.add_pack("solo")
    assert _norm(g4.descendants("solo")) == []

    print("ok")


if __name__ == "__main__":
    main()
