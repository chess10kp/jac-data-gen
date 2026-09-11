"""Reference harness: exercises every public function of iss_repobuddy__repobuddy__594."""
import importlib

mod = importlib.import_module("iss_repobuddy__repobuddy__594")
callers_of = mod.callers_of
affected_repos = mod.affected_repos

# the incident shape: shared release workflow, chained reusable workflows
G = {
    "workflows": {
        "hub/pnpm-release.yml": ["app1/ci.yml", "app2/ci.yml"],
        "app2/ci.yml": ["app3/build.yml"],
    },
    "repos": {
        "hub/pnpm-release.yml": "hub",
        "app1/ci.yml": "app1",
        "app2/ci.yml": "app2",
        "app3/build.yml": "app3",
    },
}

# bounded caller walk
assert callers_of(G, "hub/pnpm-release.yml", max_hops=1) == ["app1/ci.yml", "app2/ci.yml"]
assert callers_of(G, "hub/pnpm-release.yml", max_hops=2) == [
    "app1/ci.yml",
    "app2/ci.yml",
    "app3/build.yml",
]
assert callers_of(G, "hub/pnpm-release.yml") == [
    "app1/ci.yml",
    "app2/ci.yml",
    "app3/build.yml",
]  # default max_hops=3
assert callers_of(G, "app2/ci.yml", max_hops=1) == ["app3/build.yml"]
assert callers_of(G, "app3/build.yml") == []  # leaf: nobody calls it
assert callers_of(G, "hub/pnpm-release.yml", max_hops=0) == []

# blast radius: repo names of the full closure, duplicates collapse
G2 = {
    "workflows": {
        "hub/pnpm-release.yml": ["app1/ci.yml", "app1/nightly.yml", "app2/ci.yml"],
        "app2/ci.yml": ["app3/build.yml"],
    },
    "repos": {
        "hub/pnpm-release.yml": "hub",
        "app1/ci.yml": "app1",
        "app1/nightly.yml": "app1",
        "app2/ci.yml": "app2",
        "app3/build.yml": "app3",
    },
}
assert affected_repos(G2, "hub/pnpm-release.yml") == ["app1", "app2", "app3"]
assert affected_repos(G2, "app3/build.yml") == []
assert affected_repos(G, "app2/ci.yml") == ["app3"]

# adversarial-order diamond: long chain listed before the short caller, so
# the shared caller is first reached deep and must improve to shallow
D = {
    "workflows": {
        "hub/r.yml": ["a/w.yml", "b/w.yml"],  # long branch first
        "a/w.yml": ["m/w.yml"],
        "m/w.yml": ["top/w.yml"],
        "b/w.yml": ["top/w.yml"],
    },
    "repos": {
        "hub/r.yml": "hub",
        "a/w.yml": "a",
        "b/w.yml": "b",
        "m/w.yml": "m",
        "top/w.yml": "top",
    },
}
assert callers_of(D, "hub/r.yml", max_hops=2) == [
    "a/w.yml",
    "b/w.yml",
    "m/w.yml",
    "top/w.yml",
]  # top/w.yml at 2 hops, not 3
assert callers_of(D, "hub/r.yml") == ["a/w.yml", "b/w.yml", "m/w.yml", "top/w.yml"]

# cyclic usage graphs terminate (visited set / claim map)
C = {
    "workflows": {
        "w1.yml": ["w2.yml"],
        "w2.yml": ["w1.yml", "leaf.yml"],
    },
    "repos": {"w1.yml": "r1", "w2.yml": "r2", "leaf.yml": "r3"},
}
assert callers_of(C, "w1.yml") == ["leaf.yml", "w2.yml"]
assert affected_repos(C, "w1.yml") == ["r2", "r3"]

# refs outside the repos map do not exist: their edges are skipped
U = {
    "workflows": {
        "hub/r.yml": ["ghost/w.yml", "app/ci.yml"],
        "ghost/w.yml": ["app/nightly.yml"],
    },
    "repos": {"hub/r.yml": "hub", "app/ci.yml": "app", "app/nightly.yml": "app"},
}
assert callers_of(U, "hub/r.yml") == ["app/ci.yml"]
assert affected_repos(U, "hub/r.yml") == ["app"]

# unknown starting ref raises KeyError in both functions
for fn in (callers_of, affected_repos):
    try:
        fn(G, "ghost.yml")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

print("iss_repobuddy__repobuddy__594 ref OK")
