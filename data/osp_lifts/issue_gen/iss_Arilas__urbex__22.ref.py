"""Reference harness for iss_Arilas__urbex__22."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Arilas__urbex__22.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_chunks(
    [(0, 0), (1, 0), (2, 0), (3, 1), (4, 0)],
    [((0, 0), (1, 0)), ((1, 0), (2, 0)), ((2, 0), (3, 1)), ((3, 1), (4, 0))],
)
assert _mod.bridge_chain(g, (0, 0)) == [(0, 0), (1, 0), (2, 0)]
assert _mod.hit_cycle(g, (0, 0)) is False
cyc = _mod.load_chunks([(0, 0), (2, 0)], [((0, 0), (2, 0)), ((2, 0), (0, 0))])
assert _mod.hit_cycle(cyc, (0, 0)) is True

print("iss_Arilas__urbex__22 ref OK")
