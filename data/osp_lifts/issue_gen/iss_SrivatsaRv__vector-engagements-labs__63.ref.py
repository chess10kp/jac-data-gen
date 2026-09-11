import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod63",
    Path(__file__).with_name("iss_SrivatsaRv__vector-engagements-labs__63.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_layers(
    ["ci-local", "worker", "frontend", "integration", "browser"],
    [
        ("ci-local", "worker"),
        ("ci-local", "frontend"),
        ("frontend", "browser"),
        ("integration", "browser"),
    ],
)
assert mod.required_layers(store, ["browser"]) == ["browser", "ci-local", "frontend", "integration"]
assert mod.required_layers(store, ["integration", "worker"]) == [
    "ci-local",
    "integration",
    "worker",
]
assert mod.has_cycle(store) is False
assert mod.transitive_deps(store, "browser") == ["ci-local", "frontend", "integration"]
print("ok")
