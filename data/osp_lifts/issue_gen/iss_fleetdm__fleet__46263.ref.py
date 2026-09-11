import importlib.util
from pathlib import Path

MOD = Path(__file__).with_name("iss_fleetdm__fleet__46263.py")
spec = importlib.util.spec_from_file_location("iss_fleetdm__fleet__46263", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(mod)


def build() -> mod.InstallerBatch:
    b = mod.InstallerBatch()
    for pid, label in [("a", "A"), ("b", "B"), ("c", "C"), ("d", "D")]:
        b.add(pid, label)
    b.require("a", "b")
    b.require("b", "c")
    b.require("c", "d")
    b.require("d", "b")  # cycle
    return b


def main() -> None:
    b = build()
    assert b.closure(["a"]) == ["a", "b", "c", "d"]
    assert b.has_dependency_cycle() is True

    ok = mod.InstallerBatch()
    ok.add("x", "X")
    ok.add("y", "Y")
    ok.require("x", "y")
    assert ok.closure(["x"]) == ["x", "y"]
    assert ok.has_dependency_cycle() is False


if __name__ == "__main__":
    main()
