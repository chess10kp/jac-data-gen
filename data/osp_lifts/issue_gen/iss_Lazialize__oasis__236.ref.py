import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_Lazialize__oasis__236",
    Path(__file__).with_name("iss_Lazialize__oasis__236.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

CHAIN = mod.load_openapi_doc(
    ["paths.post", "cb.changed", "cb.notify"],
    [("paths.post", "cb.changed"), ("cb.changed", "cb.notify")],
    [],
)
assert mod.lint_reachable(CHAIN, "paths.post") == [
    "cb.changed",
    "cb.notify",
    "paths.post",
]

CYCLE = mod.load_openapi_doc(
    ["paths.post", "cb.a", "cb.b", "cb.c"],
    [("paths.post", "cb.a"), ("cb.a", "cb.b"), ("cb.b", "cb.c"), ("cb.c", "cb.a")],
    [],
)
assert mod.lint_reachable(CYCLE, "paths.post") == ["cb.a", "cb.b", "cb.c", "paths.post"]

DIAMOND = mod.load_openapi_doc(
    ["paths.post", "cb.left", "cb.right", "cb.leaf"],
    [
        ("paths.post", "cb.left"),
        ("paths.post", "cb.right"),
        ("cb.left", "cb.leaf"),
        ("cb.right", "cb.leaf"),
    ],
    [],
)
assert mod.lint_reachable(DIAMOND, "paths.post") == [
    "cb.leaf",
    "cb.left",
    "cb.right",
    "paths.post",
]

REF = mod.load_openapi_doc(
    ["paths.post", "cb.inline", "cb.component"],
    [("paths.post", "cb.inline")],
    [("cb.inline", "cb.component")],
)
assert mod.lint_reachable(REF, "paths.post") == [
    "cb.component",
    "paths.post",
]

assert mod.lint_reachable(CHAIN, "missing") == []
print("ok")
