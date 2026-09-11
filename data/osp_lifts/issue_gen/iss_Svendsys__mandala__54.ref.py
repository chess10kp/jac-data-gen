import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_Svendsys__mandala__54",
    Path(__file__).with_name("iss_Svendsys__mandala__54.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
b = mod.load_wave_board(
    ["w1a", "w1b", "w2a", "w2b"],
    [("w1a", "w2a"), ("w1b", "w2a"), ("w2a", "w2b")],
    ["w1a"],
)
assert mod.ready_set(b) == ["w1b"]
mod.mark_done(b, "w1b")
assert mod.next_wave(b) == ["w2a"]
mod.mark_done(b, "w2a")
assert mod.next_wave(b) == ["w2b"]

b_d = mod.load_wave_board(
    ["hub", "left", "right", "leaf"],
    [
        ("hub", "left"),
        ("hub", "right"),
        ("left", "leaf"),
        ("right", "leaf"),
    ],
    ["hub"],
)
assert mod.ready_set(b_d) == ["left", "right"]
print("ok")
