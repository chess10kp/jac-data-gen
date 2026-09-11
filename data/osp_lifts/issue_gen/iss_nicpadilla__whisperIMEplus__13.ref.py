#!/usr/bin/env python3
"""Reference harness for nicpadilla/whisperIMEplus#13."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_nicpadilla__whisperIMEplus__13.py"
spec = importlib.util.spec_from_file_location("roadmap_mod", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["roadmap_mod"] = mod
spec.loader.exec_module(mod)

RoadmapStore = mod.RoadmapStore
CycleError = mod.CycleError


def build_phase_priority_independent() -> RoadmapStore:
    s = RoadmapStore()
    s.add_item("ci", 0, 100)
    s.add_item("vad", 1, 90)
    s.add_item("buf", 1, 70)
    return s


def build_fork_subset() -> RoadmapStore:
    s = RoadmapStore()
    s.add_item("10", 0, 100)
    s.add_item("1", 1, 90)
    s.add_item("5", 1, 70)
    s.add_item("4", 2, 60)
    s.add_item("3", 2, 50)
    s.add_depends("4", "5")
    s.add_depends("3", "4")
    s.add_depends("3", "5")
    return s


def build_diamond_adversarial() -> RoadmapStore:
    # insertion order stresses revisit-before-deep-first-visit in walkers
    s = RoadmapStore()
    s.add_item("root", 0, 0)
    s.add_item("left", 1, 10)
    s.add_item("right", 1, 20)
    s.add_item("join", 2, 5)
    s.add_depends("join", "left")
    s.add_depends("join", "right")
    s.add_depends("left", "root")
    s.add_depends("right", "root")
    return s


def build_cycle() -> RoadmapStore:
    s = RoadmapStore()
    for iid in ("x", "y", "z"):
        s.add_item(iid, 1, 0)
    s.add_depends("y", "x")
    s.add_depends("z", "y")
    s.add_depends("x", "z")
    return s


def main() -> None:
    ind = build_phase_priority_independent()
    assert ind.find_cycle() == []
    assert ind.implementation_order() == ["ci", "vad", "buf"]
    assert ind.reachable_from("ci") == ["ci"]

    fork = build_fork_subset()
    assert fork.find_cycle() == []
    assert fork.implementation_order() == ["10", "1", "5", "4", "3"]
    assert fork.reachable_from("5") == ["3", "4", "5"]

    dia = build_diamond_adversarial()
    assert dia.find_cycle() == []
    assert dia.implementation_order() == ["root", "right", "left", "join"]
    assert dia.reachable_from("root") == ["join", "left", "root", "right"]

    cy = build_cycle()
    cyc = cy.find_cycle()
    assert len(cyc) >= 2
    assert sorted(set(cyc)) == ["x", "y", "z"]
    try:
        cy.implementation_order()
        raise AssertionError("expected CycleError")
    except CycleError:
        pass

    try:
        fork.add_depends("nope", "1")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

    try:
        fork.add_item("1", 1, 99)
        raise AssertionError("expected ValueError")
    except ValueError:
        pass

    assert fork.reachable_from("missing") == []

    print("ok")


if __name__ == "__main__":
    main()
