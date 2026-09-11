#!/usr/bin/env python3
"""Reference harness for iss_gastownhall__beads__4544.py"""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("mod", HERE / "iss_gastownhall__beads__4544.py")
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
spec.loader.exec_module(mod)


def _diamond_fanin() -> mod.DepStore:
    # Adversarial fan-in: d->a, d->b, a->c, b->c (revisit before deep first-visits)
    return mod.build_dependency_graph([("d", "a"), ("d", "b"), ("a", "c"), ("b", "c")])


def _cycle() -> mod.DepStore:
    return mod.build_dependency_graph([("a", "b"), ("b", "c"), ("c", "a")])


def _acyclic() -> mod.DepStore:
    return mod.build_dependency_graph([("x", "y"), ("y", "z")])


def main() -> None:
    for store_fn, expect_cycle in [(_cycle, True), (_acyclic, False), (_diamond_fanin, False)]:
        store = store_fn()
        assert mod.has_cycle_naive(store) is expect_cycle
        assert mod.has_cycle(store) is expect_cycle
        assert mod.all_nodes(store) == sorted(mod.all_nodes(store))

    diamond = _diamond_fanin()
    assert mod.all_nodes(diamond) == ["a", "b", "c", "d"]

    empty = mod.build_dependency_graph([])
    assert mod.has_cycle_naive(empty) is False
    assert mod.has_cycle(empty) is False
    assert mod.all_nodes(empty) == []

    print("ok")


if __name__ == "__main__":
    main()
