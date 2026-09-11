import importlib.util
from pathlib import Path

p = Path(__file__).with_suffix(".py")
spec = importlib.util.spec_from_file_location("radoub2638", p)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

load_animations = mod.load_animations
merge_sources = mod.merge_sources
merged_keys = mod.merged_keys

LINEAR = load_animations(
    [
        ("sm", "", ""),
        ("qm_idle", "idle", "qm"),
        ("rel_walk", "walk", "reliquary"),
    ],
    [("sm", "qm_idle"), ("qm_idle", "rel_walk")],
    [],
)
assert merge_sources(LINEAR, "sm") == ["qm", "reliquary"]
assert merged_keys(LINEAR, "sm") == ["idle", "walk"]

DIAMOND = load_animations(
    [
        ("sm", "", ""),
        ("left", "gate", "qm"),
        ("right", "gate", "reliquary"),
        ("shared", "shared", "qm"),
        ("deep", "deep", "reliquary"),
    ],
  # Adversarial order: right path reaches shared before left path finishes.
    [
        ("sm", "right"),
        ("sm", "left"),
        ("right", "shared"),
        ("left", "shared"),
        ("shared", "deep"),
    ],
    [],
)
assert merge_sources(DIAMOND, "sm") == ["qm", "reliquary"]
assert merged_keys(DIAMOND, "sm") == ["deep", "gate", "shared"]

CYCLE = load_animations(
    [
        ("a", "ka", "qm"),
        ("b", "kb", "reliquary"),
        ("c", "kc", "qm"),
    ],
    [],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert merge_sources(CYCLE, "a") == ["qm", "reliquary"]
assert merged_keys(CYCLE, "a") == ["ka", "kb", "kc"]

assert merge_sources(LINEAR, "missing") == []
assert merged_keys(LINEAR, "missing") == []
