#!/usr/bin/env python3
"""Reference harness for jordan-thirkle/ai-game-development-pipeline#305."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_jordan-thirkle__ai-game-development-pipeline__305.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["mod"] = mod
spec.loader.exec_module(mod)

PipelineGraph = mod.PipelineGraph


def build_perf_pipeline() -> PipelineGraph:
    g = PipelineGraph()
    for s in (
        "bundle-three",
        "vite-serve",
        "headless-browser",
        "perf-harness",
        "metrics-rollup",
    ):
        g.add_stage(s)
    g.add_dependency("headless-browser", "bundle-three")
    g.add_dependency("headless-browser", "vite-serve")
    g.add_dependency("perf-harness", "headless-browser")
    g.add_dependency("metrics-rollup", "perf-harness")
    return g


def build_cycle() -> PipelineGraph:
    g = PipelineGraph()
    for s in ("alpha", "beta", "gamma"):
        g.add_stage(s)
    g.add_dependency("beta", "alpha")
    g.add_dependency("gamma", "beta")
    g.add_dependency("alpha", "gamma")
    return g


def build_diamond_adversarial() -> PipelineGraph:
    g = PipelineGraph()
    for s in ("root", "left", "right", "join"):
        g.add_stage(s)
    g.add_dependency("join", "left")
    g.add_dependency("join", "right")
    g.add_dependency("left", "root")
    g.add_dependency("right", "root")
    return g


def main() -> None:
    perf = build_perf_pipeline()
    assert perf.find_cycle() == []
    assert perf.downstream("bundle-three") == [
        "headless-browser",
        "metrics-rollup",
        "perf-harness",
    ]
    assert perf.downstream("headless-browser") == ["metrics-rollup", "perf-harness"]
    assert perf.downstream("missing-stage") == []

    cyc = build_cycle()
    found = cyc.find_cycle()
    assert len(found) >= 2
    assert sorted(set(found)) == ["alpha", "beta", "gamma"]

    dia = build_diamond_adversarial()
    assert dia.find_cycle() == []
    assert dia.downstream("root") == ["join", "left", "right"]
    assert dia.downstream("left") == ["join"]
    assert dia.downstream("right") == ["join"]

    try:
        perf.add_dependency("nope", "bundle-three")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

    print("ok")


if __name__ == "__main__":
    main()
