#!/usr/bin/env python3
import importlib.util, pathlib, sys
MOD = pathlib.Path(__file__).with_suffix("").name
spec = importlib.util.spec_from_file_location(MOD, pathlib.Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec); sys.modules[MOD] = mod; spec.loader.exec_module(mod)

def main() -> None:
    g = mod.build_graph()
    g.add_memory("a", "alpha"); g.add_memory("b", "beta"); g.add_memory("c", "gamma")
    g.add_link("a", "b", "ref"); g.add_link("b", "c", "ref")
    assert g.reachable_from("a") == ["a", "b", "c"]
    assert g.reachable_from("missing") == []
    assert g.has_cycle() is False

    g2 = mod.build_graph()
    g2.add_memory("x", "X"); g2.add_memory("y", "Y"); g2.add_memory("z", "Z")
    g2.add_link("x", "y"); g2.add_link("y", "z"); g2.add_link("z", "x")
    assert g2.has_cycle() is True

    g3 = mod.build_graph()
    g3.add_memory("p", "P"); g3.add_memory("q", "Q"); g3.add_memory("r", "R")
    g3.add_link("p", "r"); g3.add_link("q", "r")
    assert sorted(g3.reachable_from("p")) == ["p", "r"]
    assert g3.reachable_from("q") == ["q", "r"]

if __name__ == "__main__": main()
