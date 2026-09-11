#!/usr/bin/env python3
"""Reference harness for iss_Ahaanv19__tcg_collect__46.py"""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_Ahaanv19__tcg_collect__46.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
spec.loader.exec_module(mod)


def _norm(xs: list[str]) -> list[str]:
    return sorted(xs)


def main() -> None:
    g = mod.ObjectiveGraph()
    g.link("basics", "intermediate")
    g.link("intermediate", "advanced")
    assert _norm(g.reachable_from("basics")) == ["advanced", "intermediate"]
    assert _norm(g.reachable_from("intermediate")) == ["advanced"]
    assert _norm(g.reachable_from("advanced")) == []
    assert _norm(g.reachable_from("missing")) == []

    # diamond: hub -> left/right -> capstone (adversarial insert order)
    g2 = mod.ObjectiveGraph()
    g2.link("left", "capstone")
    g2.link("right", "capstone")
    g2.link("hub", "left")
    g2.link("hub", "right")
    assert _norm(g2.reachable_from("hub")) == ["capstone", "left", "right"]

    # cycle: a->b->c->a plus d off b
    g3 = mod.ObjectiveGraph()
    g3.link("a", "b")
    g3.link("b", "c")
    g3.link("c", "a")
    g3.link("b", "d")
    assert _norm(g3.reachable_from("a")) == ["b", "c", "d"]

    print("ok")


if __name__ == "__main__":
    main()
