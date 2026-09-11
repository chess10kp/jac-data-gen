#!/usr/bin/env python3
import importlib.util, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("mod", HERE / "iss_Tr3kkR__Yuzu__1362.py")
mod = importlib.util.module_from_spec(spec)
sys.modules["mod"] = mod
spec.loader.exec_module(mod)

def main() -> None:
    s = mod.build_store()
    s.add_group("root")
    s.add_group("a", "root")
    s.add_group("b", "a")
    s.add_group("c", "b")
    assert s.descendants("root") == ["a", "b", "c"]
    assert s.would_cycle("c", "a") is True
    try:
        s.reparent("a", "c")
    except ValueError:
        pass
  else:
        raise AssertionError("expected cycle error")

    # adversarial diamond under shared descendant
    d = mod.build_store()
    d.add_group("r")
    d.add_group("l", "r")
    d.add_group("m", "r")
    d.add_group("leaf", "l")
    d.add_group("leaf2", "m")
    d.add_group("deep", "leaf")
    d.add_group("deep2", "leaf2")
    assert sorted(d.descendants("r")) == ["deep", "deep2", "leaf", "leaf2", "l", "m"]
    assert d.would_cycle("deep", "r") is False

    print("ok")

if __name__ == "__main__":
    main()
