import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_naveed949__sandcastle__20",
    Path(__file__).with_name("iss_naveed949__sandcastle__20.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

m = mod.load_mission(
    ["core", "api", "web", "deploy"],
    [("api", "core"), ("web", "api"), ("deploy", "web")],
)
assert mod.repo_build_order(m) == ["core", "api", "web", "deploy"]
assert mod.blocked_repos(m) == []

m2 = mod.load_mission(
    ["core", "api", "web"],
    [("api", "core"), ("web", "api")],
    blocked=["core"],
)
assert mod.blocked_repos(m2) == ["api", "core", "web"]

m3 = mod.load_mission(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.repo_build_order(m3) is None

m4 = mod.load_mission(
    ["hub", "left", "right", "sink"],
    [
        ("sink", "right"),
        ("hub", "right"),
        ("sink", "left"),
        ("hub", "left"),
    ],
    blocked=["left"],
)
assert mod.blocked_repos(m4) == ["hub", "left", "sink"]

print("ok")
