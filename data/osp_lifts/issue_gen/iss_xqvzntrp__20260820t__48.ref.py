import importlib.util
from pathlib import Path

p = Path(__file__).with_suffix(".py")
spec = importlib.util.spec_from_file_location("compose48", p)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

load_components = mod.load_components
composition_chain = mod.composition_chain
has_composition_cycle = mod.has_composition_cycle

CHAIN = load_components(
    [("app", "App"), ("ui", "UI"), ("core", "Core")],
    [("app", "ui"), ("ui", "core")],
)
assert composition_chain(CHAIN, "app") == ["app", "core", "ui"]
assert has_composition_cycle(CHAIN, "app") is False

CYCLE = load_components(
    [("a", "A"), ("b", "B"), ("c", "C")],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert composition_chain(CYCLE, "a") == ["a", "b", "c"]
assert has_composition_cycle(CYCLE, "a") is True

DIAMOND = load_components(
    [("pkg", "Pkg"), ("left", "L"), ("right", "R"), ("base", "B")],
    [("pkg", "left"), ("pkg", "right"), ("left", "base"), ("right", "base")],
)
assert composition_chain(DIAMOND, "pkg") == ["base", "left", "pkg", "right"]

assert composition_chain(CHAIN, "missing") == []
assert has_composition_cycle(CHAIN, "missing") is False
