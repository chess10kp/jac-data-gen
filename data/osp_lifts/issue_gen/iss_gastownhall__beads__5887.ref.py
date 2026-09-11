#!/usr/bin/env python3
"""Reference harness for iss_gastownhall__beads__5887.py"""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("mod", HERE / "iss_gastownhall__beads__5887.py")
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
spec.loader.exec_module(mod)


def _diamond() -> mod.DepStore:
    return mod.build_dependency_graph([("d", "a"), ("d", "b"), ("a", "c"), ("b", "c")])


def _cycle() -> mod.DepStore:
    return mod.build_dependency_graph([("a", "b"), ("b", "c"), ("c", "a")])


def _tree() -> mod.DepStore:
    return mod.build_dependency_graph([("r", "a"), ("r", "b"), ("a", "c")])


def main() -> None:
    diamond = _diamond()
    assert mod.render_tree_naive(diamond, "d") == ["d", "a", "c", "b", "c"]
    assert mod.has_cycle(diamond) is False
    assert mod.render_tree(diamond, "d") == ["d", "a", "c", "b"]

    tree = _tree()
    assert mod.render_tree(tree, "r") == ["r", "a", "c", "b"]
    assert mod.all_nodes(tree) == ["a", "b", "c", "r"]

    cyc = _cycle()
    assert mod.has_cycle(cyc) is True
    try:
        mod.render_tree(cyc, "a")
        raise AssertionError("expected ValueError")
    except ValueError:
        pass

    try:
        mod.render_tree(tree, "missing")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

    print("ok")


if __name__ == "__main__":
    main()
