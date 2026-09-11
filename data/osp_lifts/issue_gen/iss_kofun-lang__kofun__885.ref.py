#!/usr/bin/env python3
import importlib.util, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("mod", HERE / "iss_kofun-lang__kofun__885.py")
mod = importlib.util.module_from_spec(spec); sys.modules["mod"] = mod; spec.loader.exec_module(mod)

def main() -> None:
    g = mod.build_schema_graph(["a","b","c","d"], [("b","a"),("c","a"),("d","c")])
    assert mod.ancestors(g, "d") == ["c", "a"]
    assert mod.semantic_frontier(g, ["a"]) == ["b", "c", "d"]
    diamond = mod.build_schema_graph(["r","l","x","t"], [("l","r"),("x","r"),("t","l"),("t","x")])
    assert mod.semantic_frontier(diamond, ["r"]) == ["l", "t", "x"]
    assert mod.ancestors(diamond, "missing") == []
    print("ok")

if __name__ == "__main__": main()
