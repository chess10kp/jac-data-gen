#!/usr/bin/env python3
import importlib.util
import pathlib
import sys

MOD = pathlib.Path(__file__).with_suffix("").name
spec = importlib.util.spec_from_file_location(MOD, pathlib.Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
sys.modules[MOD] = mod
spec.loader.exec_module(mod)


def main() -> None:
    p = mod.build_processor()
    p.register_row("a", "A")
    p.register_row("b", "B", parent_id="a")
    p.register_row("c", "C", parent_id="a")
    assert p.processing_order() == ["a", "b", "c"]
    assert p.unreachable() == []
    assert p.read_simulated("b") == "B"

    p2 = mod.build_processor()
    p2.register_row("x", "X")
    p2.register_row("y", "Y", parent_id="z")
    p2.register_row("z", "Z")
    assert p2.processing_order() == ["x", "z", "y"]
    assert p2.unreachable() == []

    p3 = mod.build_processor()
    p3.register_row("1", "one")
    p3.register_row("2", "two", parent_id="3")
    p3.register_row("3", "three", parent_id="2")
    assert sorted(p3.unreachable()) == ["2", "3"]
    assert p3.processing_order() == ["1"]

    try:
        p.read_simulated("missing")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


if __name__ == "__main__":
    main()
