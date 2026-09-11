"""Reference harness for samitoyang/skill-customization#29."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD_PATH = HERE / "iss_samitoyang__skill-customization__29.py"
spec = importlib.util.spec_from_file_location("sk29_mod", MOD_PATH)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["sk29_mod"] = mod
spec.loader.exec_module(mod)

load_modules = mod.load_modules
child_modules = mod.child_modules
ancestor_modules = mod.ancestor_modules
blocking_deps = mod.blocking_deps
transitive_blockers = mod.transitive_blockers
frontier = mod.frontier
migration_order = mod.migration_order


def _specs_main():
    return [
        ("provenance", None, []),
        ("registry", None, ["provenance"]),
        ("host_adapters", "registry", ["registry"]),
        ("descriptor", None, ["registry"]),
        ("binding", None, ["descriptor"]),
        ("preflight", None, ["binding"]),
        ("reconciliation", None, ["binding", "preflight"]),
    ]


def main() -> None:
    g = load_modules(_specs_main())
    assert child_modules(g, "registry") == ["host_adapters"]
    assert child_modules(g, "missing") == []
    assert ancestor_modules(g, "host_adapters") == ["registry"]
    assert ancestor_modules(g, "provenance") == []
    assert ancestor_modules(g, "missing") == []
    assert blocking_deps(g, "reconciliation") == ["binding", "preflight"]
    assert blocking_deps(g, "missing") == []
    assert transitive_blockers(g, "reconciliation") == [
        "binding",
        "descriptor",
        "preflight",
        "provenance",
        "registry",
    ]
    assert transitive_blockers(g, "provenance") == []
    assert transitive_blockers(g, "missing") == []
    assert frontier(g, []) == ["provenance"]
    assert frontier(g, ["provenance"]) == ["registry"]
    assert frontier(g, ["provenance", "registry", "descriptor", "binding", "preflight"]) == [
        "host_adapters",
        "reconciliation",
    ]
    assert migration_order(g) == [
        "binding",
        "descriptor",
        "host_adapters",
        "preflight",
        "provenance",
        "reconciliation",
        "registry",
    ]

    cyc = load_modules([
        ("a", None, ["b"]),
        ("b", None, ["c"]),
        ("c", None, ["a"]),
    ])
    assert migration_order(cyc) is None

    # adversarial diamond: shared blocker inserted first
    g2 = load_modules([
        ("sink", None, []),
        ("left", None, ["sink"]),
        ("right", None, ["sink"]),
        ("top", None, ["left", "right"]),
    ])
    assert transitive_blockers(g2, "top") == ["left", "right", "sink"]
    assert migration_order(g2) == ["left", "right", "sink", "top"]
    print("ok")


if __name__ == "__main__":
    main()
