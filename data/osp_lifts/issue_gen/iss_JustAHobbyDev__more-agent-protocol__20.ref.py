#!/usr/bin/env python3
"""Reference harness for JustAHobbyDev/more-agent-protocol#20."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_JustAHobbyDev__more-agent-protocol__20.py"
spec = importlib.util.spec_from_file_location("map_mod", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["map_mod"] = mod
spec.loader.exec_module(mod)

build_coord_graph = mod.build_coord_graph
manager_chain = mod.manager_chain
delegated_subtree = mod.delegated_subtree
coord_successors = mod.coord_successors
coord_reachable = mod.coord_reachable
reconcile = mod.reconcile


def _main_fixture():
    return [
        ("director", None, []),
        ("mgr", "director", ["peer_lead"]),
        ("peer_lead", "director", []),
        ("lead", "mgr", ["worker_b"]),
        ("worker_a", "lead", ["worker_b"]),
        ("worker_b", "lead", []),
        ("outsider", "peer_lead", []),
    ]


def main() -> None:
    g = build_coord_graph(_main_fixture())

    assert manager_chain(g, "worker_a") == ["lead", "mgr", "director"]
    assert manager_chain(g, "director") == []
    assert manager_chain(g, "missing") == []

    assert delegated_subtree(g, "mgr") == ["lead", "mgr", "worker_a", "worker_b"]
    assert delegated_subtree(g, "lead") == ["lead", "worker_a", "worker_b"]
    assert delegated_subtree(g, "missing") == []

    assert coord_successors(g, "worker_a") == ["worker_b"]
    assert coord_successors(g, "worker_b") == []
    assert coord_successors(g, "missing") == []

    assert coord_reachable(g, "mgr") == ["lead", "peer_lead", "worker_a", "worker_b"]
    assert coord_reachable(g, "worker_b") == []

    assert reconcile(g, "mgr") == ["mgr->peer_lead"]
    assert reconcile(g, "lead") == []
    assert reconcile(g, "director") == []
    assert reconcile(g, "missing") == []

    # adversarial diamond: sink inserted before arms
    g2 = build_coord_graph([
        ("sink", None, []),
        ("left", None, ["sink"]),
        ("right", None, ["sink"]),
        ("hub", None, ["left", "right"]),
    ])
    assert coord_reachable(g2, "hub") == ["left", "right", "sink"]

    # coord cycle must not hang; claim-map semantics
    g3 = build_coord_graph([
        ("a", None, ["b"]),
        ("b", None, ["c"]),
        ("c", None, ["a", "d"]),
        ("d", None, []),
    ])
    assert coord_reachable(g3, "a") == ["b", "c", "d"]

    print("ok")


if __name__ == "__main__":
    main()
