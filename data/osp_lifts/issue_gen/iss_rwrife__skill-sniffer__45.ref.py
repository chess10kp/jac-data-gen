import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_rwrife__skill-sniffer__45",
    Path(__file__).with_name("iss_rwrife__skill-sniffer__45.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

b = mod.load_bundle(
    ["SKILL.md", "scripts/setup.sh", "assets/logo.png", "refs/guide.md"],
    [
        ("SKILL.md", "scripts/setup.sh"),
        ("SKILL.md", "refs/guide.md"),
        ("refs/guide.md", "assets/logo.png"),
    ],
)
assert mod.follow_refs(b, "SKILL.md", 2) == [
    "SKILL.md",
    "assets/logo.png",
    "refs/guide.md",
    "scripts/setup.sh",
]
assert mod.follow_refs(b, "SKILL.md", 1) == [
    "SKILL.md",
    "refs/guide.md",
    "scripts/setup.sh",
]
assert mod.follow_refs(b, "missing", 3) == []

cyc = mod.load_bundle(["a", "b", "c"], [("a", "b"), ("b", "c"), ("c", "a")])
assert mod.follow_refs(cyc, "a", 5) == ["a", "b", "c"]

print("ok")
