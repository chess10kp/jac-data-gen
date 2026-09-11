#!/usr/bin/env python3
"""Reference harness for backspring-labs/squad-ops#578."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_backspring-labs__squad-ops__578.py"
spec = importlib.util.spec_from_file_location("plan_mod", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["plan_mod"] = mod
spec.loader.exec_module(mod)

PlanStore = mod.PlanStore
CycleError = mod.CycleError


def build_acyclic() -> PlanStore:
  s = PlanStore()
  for t in ("a", "b", "c", "d"):
    s.add_task(t)
  s.add_depends_on("b", "a")
  s.add_depends_on("c", "a")
  s.add_depends_on("d", "b")
  s.add_depends_on("d", "c")
  return s


def build_cycle() -> PlanStore:
  s = PlanStore()
  for t in ("x", "y", "z"):
    s.add_task(t)
  s.add_depends_on("y", "x")
  s.add_depends_on("z", "y")
  s.add_depends_on("x", "z")
  return s


def build_diamond_adversarial() -> PlanStore:
  # insertion order forces revisit-before-deep-first-visit patterns in naive walkers
  s = PlanStore()
  for t in ("root", "left", "right", "join"):
    s.add_task(t)
  s.add_depends_on("join", "left")
  s.add_depends_on("join", "right")
  s.add_depends_on("left", "root")
  s.add_depends_on("right", "root")
  return s


def main() -> None:
  ac = build_acyclic()
  assert ac.find_cycle() == []
  assert ac.execution_order() == ["a", "b", "c", "d"]

  cy = build_cycle()
  cyc = cy.find_cycle()
  assert len(cyc) >= 2
  assert set(cyc[:-1]) == {"x", "y", "z"} or set(cyc) == {"x", "y", "z"}
  try:
    cy.execution_order()
    raise AssertionError("expected CycleError")
  except CycleError:
    pass

  dia = build_diamond_adversarial()
  assert dia.find_cycle() == []
  assert dia.execution_order() == ["root", "left", "right", "join"]
  assert dia.reachable_from("root") == ["join", "left", "right", "root"]

  try:
    ac.add_depends_on("nope", "a")
    raise AssertionError("expected KeyError")
  except KeyError:
    pass

  print("ok")


if __name__ == "__main__":
  main()
