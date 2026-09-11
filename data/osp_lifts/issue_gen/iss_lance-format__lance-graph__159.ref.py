#!/usr/bin/env python3
"""Reference harness for iss_lance-format__lance-graph__159.py"""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_lance-format__lance-graph__159.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
spec.loader.exec_module(mod)


def main() -> None:
    g = mod.build_csr([("a", "b"), ("b", "c"), ("c", "a"), ("a", "d")])
    assert mod.neighbors_csr(g, "a") == ["b", "d"]
    assert mod.neighbors_csr(g, "missing") == []
    bfs = mod.reachable_bfs(g, "a")
    dfs = mod.reachable_dfs(g, "a")
    assert bfs == dfs == ["a", "b", "c", "d"]

    diamond = mod.build_csr([("s", "l"), ("s", "r"), ("r", "t"), ("l", "t")])
    assert mod.reachable_bfs(diamond, "s") == ["l", "r", "s", "t"]

    empty = mod.build_csr([])
    assert mod.reachable_bfs(empty, "x") == []
    print("ok")


if __name__ == "__main__":
    main()
