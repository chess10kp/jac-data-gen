#!/usr/bin/env python3
"""Reference harness for iss_Arkeon-Technologies__arkeon__6.py"""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_Arkeon-Technologies__arkeon__6.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
assert spec.loader is not None
spec.loader.exec_module(mod)


def _norm(xs: list[str]) -> list[str]:
    return sorted(xs)


def main() -> None:
    g = mod.TraversalGraph()
    g.link("a", "b", "road")
    g.link("b", "c", "ferry")
    g.link("b", "d", "road")
    assert _norm(g.traverse("a", 3, {"road"})) == ["b", "d"]
    assert _norm(g.traverse("a", 1, {"road"})) == ["b"]
    assert _norm(g.traverse("missing", 2, {"road"})) == []

    g2 = mod.TraversalGraph()
    g2.link("left", "cap", "walk")
    g2.link("right", "cap", "walk")
    g2.link("hub", "left", "walk")
    g2.link("hub", "right", "walk")
    assert _norm(g2.traverse("hub", 2, {"walk"})) == ["cap", "left", "right"]

    g3 = mod.TraversalGraph()
    g3.link("a", "b", "walk")
    g3.link("b", "c", "walk")
    g3.link("c", "a", "walk")
    g3.link("b", "d", "walk")
    assert _norm(g3.traverse("a", 5, {"walk"})) == ["b", "c", "d"]

    g4 = mod.TraversalGraph()
    g4.link("a", "b", "road")
    g4.link("b", "c", "road")
    g4.link("a", "x", "road")
    g4.link("x", "c", "road")
    assert g4.shortest_path("a", "c", 3, {"road"}) == ["a", "b", "c"]
    assert g4.shortest_path("a", "c", 1, {"road"}) is None
    g5 = mod.TraversalGraph()
    g5.link("p", "q", "ferry")
    assert g5.shortest_path("p", "q", 2, {"road"}) is None
    assert g4.shortest_path("a", "a", 0, {"road"}) == ["a"]
    assert g4.shortest_path("nope", "c", 3, {"road"}) is None

    print("ok")


if __name__ == "__main__":
    main()
