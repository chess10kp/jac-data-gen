import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_Monkopedia__sdbus-kotlin__253.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

DEPS = {
    "build-samples": ["kotlin-stdlib", "sdbus-api"],
    "kotlin-stdlib": ["kotlin-reflect"],
}
CACHE = {"kotlin-stdlib": "1.9.0"}

hits, misses = mod.resolve_with_cache("build-samples", DEPS, CACHE)
assert hits == ["kotlin-stdlib"]
assert misses == ["build-samples", "kotlin-reflect", "sdbus-api"]

DIAMOND = {"root": ["a", "b"], "a": ["shared"], "b": ["shared"]}
_, diamond_misses = mod.resolve_with_cache("root", DIAMOND, {})
assert diamond_misses.count("shared") == 1
assert sorted(diamond_misses) == ["a", "b", "root", "shared"]

PARENT = {
    "arm-runtime-tests": "arm-build-test.yaml",
    "pages-build": "pages.yaml",
}
assert mod.ancestor_chain("arm-runtime-tests", PARENT) == ["arm-build-test.yaml"]
assert mod.uncached_misses(["a", "b", "c", "b"], {"b"}) == ["a", "c"]
print("ok")
