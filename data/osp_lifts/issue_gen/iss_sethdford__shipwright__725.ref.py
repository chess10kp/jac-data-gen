import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_sethdford__shipwright__725",
    Path(__file__).with_name("iss_sethdford__shipwright__725.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

PIPELINES = ["fetch", "build", "test", "deploy"]
DEPS = [("fetch", "build"), ("build", "test"), ("test", "deploy")]
MEMO = [("deploy", "fetch")]

c = mod.build_cache(PIPELINES, DEPS, MEMO)

assert mod.store_result(c, "build", "artifact:v1") is True
assert mod.read_result(c, "build") == "artifact:v1"
assert mod.store_result(c, "deploy", "bundle:v1") is True
assert mod.downstream_pipelines(c, "build") == ["deploy", "test"]
assert mod.downstream_pipelines(c, "ghost") == []

inv = mod.build_cache(PIPELINES, DEPS, MEMO)
assert mod.store_result(inv, "test", "t1") is True
assert mod.store_result(inv, "deploy", "d1") is True
assert mod.invalidate_on_change(inv, "build") == ["build", "deploy", "fetch", "test"]
assert mod.read_result(inv, "test") is None
assert mod.read_result(inv, "deploy") is None

diamond = mod.build_cache(
    ["hub", "left", "right", "sink"],
    [("hub", "left"), ("hub", "right"), ("left", "sink"), ("right", "sink")],
)
assert mod.downstream_pipelines(diamond, "hub") == ["left", "right", "sink"]

cycle = mod.build_cache(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.downstream_pipelines(cycle, "a") == ["b", "c"]

assert mod.store_result(c, "missing", "x") is False
assert mod.invalidate_on_change(c, "missing") == []

print("ok")
