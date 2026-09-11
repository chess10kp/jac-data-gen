#!/usr/bin/env python3
"""Reference harness for dunay2/dvt#2594."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_dunay2__dvt__2594.py"
spec = importlib.util.spec_from_file_location("card_mod", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["card_mod"] = mod
spec.loader.exec_module(mod)

CardPipeline = mod.CardPipeline
CycleError = mod.CycleError


def build_acyclic() -> CardPipeline:
    p = CardPipeline()
    for c in ("read", "filter", "project", "write"):
        p.add_card(c)
    p.depends("filter", "read")
    p.depends("project", "read")
    p.depends("write", "filter")
    p.depends("write", "project")
    return p


def build_cycle() -> CardPipeline:
    p = CardPipeline()
    for c in ("a", "b", "c"):
        p.add_card(c)
    p.depends("b", "a")
    p.depends("c", "b")
    p.depends("a", "c")
    return p


def build_diamond_adversarial() -> CardPipeline:
    p = CardPipeline()
    for c in ("root", "left", "right", "join"):
        p.add_card(c)
    p.depends("join", "left")
    p.depends("join", "right")
    p.depends("left", "root")
    p.depends("right", "root")
    return p


def main() -> None:
    ac = build_acyclic()
    assert ac.linearize() == ["read", "filter", "project", "write"]
    assert ac.downstream("read") == ["filter", "project", "read", "write"]

    cy = build_cycle()
    cyc = cy._find_cycle()
    assert len(cyc) >= 2
    assert sorted(set(cyc)) == ["a", "b", "c"]
    try:
        cy.linearize()
        raise AssertionError("expected CycleError")
    except CycleError:
        pass

    dia = build_diamond_adversarial()
    assert dia.linearize() == ["root", "left", "right", "join"]
    assert dia.downstream("root") == ["join", "left", "right", "root"]

    assert ac.downstream("missing") == []

    try:
        ac.depends("nope", "read")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

    print("ok")


if __name__ == "__main__":
    main()
