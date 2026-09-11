#!/usr/bin/env python3
"""Reference harness for EffortlessMetrics/perl-lsp-swarm#8143."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "iss_EffortlessMetrics__perl-lsp-swarm__8143",
    HERE / "iss_EffortlessMetrics__perl-lsp-swarm__8143.py",
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)

load_symbols = mod.load_symbols
ordered_parents = mod.ordered_parents
typed_refs = mod.typed_refs
ref_closure = mod.ref_closure
ancestor_chain = mod.ancestor_chain

ENTITIES = [
    ("Pkg::Child", "child.pm:10"),
    ("Pkg::Role", "role.pm:3"),
    ("Pkg::Base", "base.pm:1"),
    ("Pkg::Util", "util.pm:5"),
    ("t_child", "t/child.t:1"),
]

PARENTS = [("Pkg::Child", ["Pkg::Role", "Pkg::Base"])]
USES = [("Pkg::Child", "Pkg::Util"), ("Pkg::Role", "Pkg::Base")]
TESTS = [("t_child", "Pkg::Child")]


def main() -> None:
    g = load_symbols(ENTITIES, PARENTS, USES, TESTS)

    assert ordered_parents(g, "Pkg::Child") == ["Pkg::Role", "Pkg::Base"]
    assert ordered_parents(g, "missing") == []

    assert typed_refs(g, "Pkg::Child", "Uses") == ["Pkg::Util"]
    assert typed_refs(g, "Pkg::Child", "Inherits") == ["Pkg::Base", "Pkg::Role"]
    assert typed_refs(g, "t_child", "Tests") == ["Pkg::Child"]
    assert typed_refs(g, "nope", "Uses") == []

    assert ref_closure(g, "Pkg::Child") == [
        "Pkg::Base",
        "Pkg::Child",
        "Pkg::Role",
        "Pkg::Util",
    ]
    assert ref_closure(g, "missing") == []

    assert ancestor_chain(g, "Pkg::Child") == [
        "Pkg::Child",
        "Pkg::Role",
        "Pkg::Base",
    ]

    # Diamond adversarial fixture (shared fan-in)
    d = load_symbols(
        [("d", "d.pm"), ("a", "a.pm"), ("b", "b.pm"), ("c", "c.pm")],
        [],
        [("d", "a"), ("d", "b"), ("a", "c"), ("b", "c")],
        [],
    )
    assert ref_closure(d, "d") == ["a", "b", "c", "d"]

    # Inheritance cycle must not blow up
    cyc = load_symbols(
        [("A", "a.pm"), ("B", "b.pm"), ("C", "c.pm")],
        [("A", ["B"]), ("B", ["C"]), ("C", ["A"])],
        [],
        [],
    )
    assert sorted(ref_closure(cyc, "A")) == ["A", "B", "C"]
    assert ancestor_chain(cyc, "A") == ["A", "B", "C"]

    print("ok")


if __name__ == "__main__":
    main()
