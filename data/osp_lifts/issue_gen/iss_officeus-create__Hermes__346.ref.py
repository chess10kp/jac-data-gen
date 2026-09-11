#!/usr/bin/env python3
"""Reference harness for officeus-create/Hermes#346."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_officeus-create__Hermes__346.py"
spec = importlib.util.spec_from_file_location("backlog_mod", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["backlog_mod"] = mod
spec.loader.exec_module(mod)

BacklogStore = mod.BacklogStore
CycleError = mod.CycleError


def build_revenue_independent() -> BacklogStore:
    s = BacklogStore()
    s.add_task("lo", 10)
    s.add_task("hi", 50)
    s.add_task("mid", 30)
    return s


def build_acyclic_fan() -> BacklogStore:
    s = BacklogStore()
    for tid in ("a", "b", "c", "d"):
        s.add_task(tid, 0)
    s.add_depends("b", "a")
    s.add_depends("c", "a")
    s.add_depends("d", "b")
    s.add_depends("d", "c")
    return s


def build_diamond_adversarial() -> BacklogStore:
    # insertion order stresses revisit-before-deep-first-visit in walkers
    s = BacklogStore()
    s.add_task("root", 0)
    s.add_task("left", 10)
    s.add_task("right", 20)
    s.add_task("join", 5)
    s.add_depends("join", "left")
    s.add_depends("join", "right")
    s.add_depends("left", "root")
    s.add_depends("right", "root")
    return s


def build_cycle() -> BacklogStore:
    s = BacklogStore()
    for tid in ("x", "y", "z"):
        s.add_task(tid, 0)
    s.add_depends("y", "x")
    s.add_depends("z", "y")
    s.add_depends("x", "z")
    return s


def main() -> None:
    rev = build_revenue_independent()
    assert rev.find_cycle() == []
    assert rev.execution_order() == ["hi", "mid", "lo"]
    assert rev.reachable_from("hi") == ["hi"]

    fan = build_acyclic_fan()
    assert fan.find_cycle() == []
    assert fan.execution_order() == ["a", "b", "c", "d"]
    assert fan.reachable_from("a") == ["a", "b", "c", "d"]

    dia = build_diamond_adversarial()
    assert dia.find_cycle() == []
    assert dia.execution_order() == ["root", "right", "left", "join"]
    assert dia.reachable_from("root") == ["join", "left", "root", "right"]

    cy = build_cycle()
    cyc = cy.find_cycle()
    assert len(cyc) >= 2
    assert sorted(set(cyc)) == ["x", "y", "z"]
    try:
        cy.execution_order()
        raise AssertionError("expected CycleError")
    except CycleError:
        pass

    try:
        fan.add_depends("nope", "a")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

    try:
        fan.add_task("a", 99)
        raise AssertionError("expected ValueError")
    except ValueError:
        pass

    assert fan.reachable_from("missing") == []

    print("ok")


if __name__ == "__main__":
    main()
