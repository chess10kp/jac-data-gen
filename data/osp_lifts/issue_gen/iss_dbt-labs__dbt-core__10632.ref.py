#!/usr/bin/env python3
"""Reference harness for dbt-labs/dbt-core#10632."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_dbt-labs__dbt-core__10632.py"
spec = importlib.util.spec_from_file_location("dbt_mod", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["dbt_mod"] = mod
spec.loader.exec_module(mod)

ModelDag = mod.ModelDag


def build_priority_fixture() -> ModelDag:
    g = ModelDag()
    g.add_model("quick_a")
    g.add_model("quick_b")
    g.add_model("long_run", execution_order=1)
    g.add_model("downstream")
    g.add_ref("downstream", "long_run")
    g.add_ref("downstream", "quick_a")
    return g


def build_diamond_adversarial() -> ModelDag:
    # Stress insertion order: join before arms
    g = ModelDag()
    g.add_model("join", execution_order=5)
    g.add_model("root")
    g.add_model("left", execution_order=2)
    g.add_model("right", execution_order=1)
    g.add_ref("left", "root")
    g.add_ref("right", "root")
    g.add_ref("join", "left")
    g.add_ref("join", "right")
    return g


def main() -> None:
    g = build_priority_fixture()
    assert g.ready_models(set()) == ["long_run", "quick_a", "quick_b"]
    assert g.ready_models({"long_run"}) == ["quick_a", "quick_b"]
    assert g.ready_models({"long_run", "quick_a", "quick_b"}) == ["downstream"]
    assert g.has_cycle() is False
    assert g.execution_order() == [
        "long_run", "quick_a", "quick_b", "downstream",
    ]

    dia = build_diamond_adversarial()
    assert dia.has_cycle() is False
    assert dia.execution_order() == ["root", "right", "left", "join"]
    assert dia.ready_models(set()) == ["root"]

    cyc = ModelDag()
    for n in ("a", "b", "c"):
        cyc.add_model(n)
    cyc.add_ref("b", "a")
    cyc.add_ref("c", "b")
    cyc.add_ref("a", "c")
    assert cyc.has_cycle() is True
    assert cyc.execution_order() is None

    empty = ModelDag()
    assert empty.ready_models(set()) == []
    assert empty.execution_order() == []

    try:
        g.add_ref("nope", "long_run")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

    print("ok")


if __name__ == "__main__":
    main()
