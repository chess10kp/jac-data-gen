#!/usr/bin/env python3
import importlib.util, pathlib, sys
MOD = pathlib.Path(__file__).with_suffix(".py")
spec = importlib.util.spec_from_file_location("reaper_mod", MOD)
mod = importlib.util.module_from_spec(spec); assert spec.loader
sys.modules["reaper_mod"] = mod; spec.loader.exec_module(mod)

def main() -> None:
    g = mod.build_reaper()
    for s in ("read", "join", "agg", "emit"):
        g.add_step(s)
    g.add_depends("join", "read")
    g.add_depends("agg", "join")
    g.add_depends("emit", "agg")
    assert g.query_layers() == [["read"], ["join"], ["agg"], ["emit"]]
    assert g.reachable_downstream("read") == ["agg", "emit", "join", "read"]
    cy = mod.build_reaper()
    for s in ("a", "b", "c"):
        cy.add_step(s)
    cy.add_depends("b", "a"); cy.add_depends("c", "b"); cy.add_depends("a", "c")
    try:
        cy.query_layers()
        raise AssertionError("expected CycleError")
    except mod.CycleError:
        pass
    print("ok")

if __name__ == "__main__":
    main()
