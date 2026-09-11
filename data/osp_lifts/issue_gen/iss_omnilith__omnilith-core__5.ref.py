#!/usr/bin/env python3
import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_omnilith__omnilith-core__5.py"
spec = importlib.util.spec_from_file_location("omnilith_rel", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
sys.modules["omnilith_rel"] = mod
spec.loader.exec_module(mod)


def main() -> None:
    g = mod.build_graph()
    g.add_entity("a")
    g.add_entity("b")
    g.add_entity("c")
    g.link("a", "b")
    g.link("b", "c")
    assert g.reachable_from("a") == ["a", "b", "c"]
    assert g.reachable_from("missing") == []
    assert g.has_cycle() is False

    g2 = mod.build_graph()
    g2.add_entity("x")
    g2.add_entity("y")
    g2.add_entity("z")
    g2.link("x", "y")
    g2.link("y", "z")
    g2.link("z", "x")
    assert g2.has_cycle() is True

    # adversarial diamond: back-edge inserted last so revisit fires early
    g3 = mod.build_graph()
    g3.add_entity("top")
    g3.add_entity("left")
    g3.add_entity("right")
    g3.add_entity("bot")
    g3.link("top", "left")
    g3.link("top", "right")
    g3.link("left", "bot")
    g3.link("right", "bot")
    g3.link("bot", "top")
    assert g3.has_cycle() is True
    assert sorted(g3.reachable_from("top")) == ["bot", "left", "right", "top"]

    g4 = mod.build_graph()
    g4.add_entity("p")
    g4.add_entity("q")
    g4.add_entity("r")
    g4.link("p", "r")
    g4.link("q", "r")
    assert sorted(g4.reachable_from("p")) == ["p", "r"]
    assert g4.reachable_from("q") == ["q", "r"]

    print("ok")


if __name__ == "__main__":
    main()
