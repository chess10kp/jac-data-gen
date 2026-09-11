"""Reference harness: exercises every public function of iss_thomascarter613__monad-workspace__165."""
import importlib

mod = importlib.import_module("iss_thomascarter613__monad-workspace__165")
impacted = mod.impacted
recommend_tests = mod.recommend_tests

model = {
    "components": {
        "web": ["src/a.py", "src/b.py"],
        "core": ["lib/c.py"],
        "docs": ["docs/readme.md"],
    },
    "tasks": {
        "build": ["web", "core"],
        "test-web": ["web"],
        "publish-docs": ["docs"],
    },
    "tests": {
        "e2e-web": ["test-web"],
        "unit-build": ["build"],
        "docs-lint": ["publish-docs"],
    },
}

# full ripple: file -> component -> tasks -> tests
res = impacted(model, ["src/a.py"])
assert res == {"components": ["web"], "tasks": ["build", "test-web"], "tests": ["e2e-web", "unit-build"]}

# multiple changed files union their blast radii
res = impacted(model, ["src/a.py", "lib/c.py"])
assert res == {
    "components": ["core", "web"],
    "tasks": ["build", "test-web"],
    "tests": ["e2e-web", "unit-build"],
}

# recommend_tests is the verification slice of the same ripple
assert recommend_tests(model, ["docs/readme.md"]) == ["docs-lint"]
assert recommend_tests(model, ["src/a.py", "lib/c.py"]) == ["e2e-web", "unit-build"]

# diamond: a file owned by two components, and a task depending on both --
# the ripple reaches the task and its tests once, not twice
diamond = {
    "components": {"api": ["shared.py"], "cli": ["shared.py"]},
    "tasks": {"build-cli": ["cli"], "build-all": ["api", "cli"]},
    "tests": {"t-all": ["build-all"], "t-cli": ["build-cli"]},
}
res = impacted(diamond, ["shared.py"])
assert res == {
    "components": ["api", "cli"],
    "tasks": ["build-all", "build-cli"],
    "tests": ["t-all", "t-cli"],
}

# tasks on unimpacted components and their tests stay out
res = impacted(model, ["docs/readme.md"])
assert res == {"components": ["docs"], "tasks": ["publish-docs"], "tests": ["docs-lint"]}

# a changed file owned by no component has no impact at all
res = impacted(model, ["orphan.rs"])
assert res == {"components": [], "tasks": [], "tests": []}
assert recommend_tests(model, ["orphan.rs"]) == []

# empty change set impacts nothing
assert impacted(model, []) == {"components": [], "tasks": [], "tests": []}

print("iss_thomascarter613__monad-workspace__165 ref OK")
