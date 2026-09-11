"""Reference harness: exercises every public function of rec_15."""
from rec_15_dep_audit import build_workspace, closure, depends_on_chain

ws = build_workspace(
    ["app", "web", "api", "core", "util", "ext"],
    [
        ("app", "web", "runtime"),
        ("app", "api", "runtime"),
        ("web", "core", "runtime"),
        ("api", "core", "build"),
        ("core", "util", "runtime"),
    ],
)

assert closure(ws, "app") == ["api", "core", "util", "web"]
assert closure(ws, "core") == ["util"]
assert closure(ws, "util") == []

assert depends_on_chain(ws, "app", "util")
assert not depends_on_chain(ws, "util", "app")
assert not depends_on_chain(ws, "util", "util")   # no self edge

# Unknown modules.
assert closure(ws, "ghost") == []
assert not depends_on_chain(ws, "app", "ghost")
assert not depends_on_chain(ws, "ghost", "app")

# Dependency cycle: must terminate, root excluded once, chain through cycle works.
cyc = build_workspace(
    ["a", "b", "c"],
    [("a", "b", "runtime"), ("b", "c", "runtime"), ("c", "a", "runtime")],
)
assert closure(cyc, "a") == ["b", "c"]
assert depends_on_chain(cyc, "a", "a")   # cycle makes a its own descendant
assert depends_on_chain(cyc, "c", "b")

print("rec_15 ref OK")
