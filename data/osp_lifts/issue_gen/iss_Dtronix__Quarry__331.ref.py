#!/usr/bin/env python3
import importlib.util, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("q", HERE / "iss_Dtronix__Quarry__331.py")
mod = importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(mod)

def main() -> None:
    r = mod.build_registry()
    r.register_with("base", [])
    r.register_with("step1", ["base"])
    r.register_with("step2", ["step1", "base"])
    assert r.column_context("step2") == ["base", "step1", "step2"]
    assert r.reachable_ctes("nope") == []
    r2 = mod.build_registry()
    r2.register_with("a", ["missing"])
    assert r2.has_unknown_ref("a") is True
    print("ok")

if __name__ == "__main__": main()
