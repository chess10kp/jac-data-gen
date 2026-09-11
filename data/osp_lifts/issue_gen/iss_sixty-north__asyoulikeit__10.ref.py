"""Reference harness: exercises every public function of iss_sixty-north__asyoulikeit__10."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "ayl10", Path(__file__).parent / "iss_sixty-north__asyoulikeit__10.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["ayl10"] = mod
spec.loader.exec_module(mod)

g = mod.GraphContent(title="call graph")
for nid, name, ext in [
    ("0x8000", "init", False),
    ("0xFFEE", "oswrch", True),
    ("0x8050", "main", False),
    ("0x9000", "irq", False),
]:
    g.add_node(nid, name=name, external=ext)
g.add_edge("0x8000", "0x8050", "jsr")
g.add_edge("0x8050", "0xFFEE", "jsr")
g.add_edge("0x9000", "0xFFEE", "jmp")

assert g.successors("0x8000") == ["0x8050"]
assert g.successors("0xFFEE") == []
assert sorted(g.reachable("0x8000")) == ["0x8000", "0x8050", "0xFFEE"]

# Diamond: shared endpoint reachable via two branches, counted once.
d = mod.GraphContent()
d.add_node("a").add_node("b1").add_node("b2").add_node("shared")
d.add_edge("a", "b1").add_edge("a", "b2")
d.add_edge("b1", "shared").add_edge("b2", "shared")
assert d.reachable("a") == ["a", "b1", "b2", "shared"]

dot = g.to_dot()
lines = dot.splitlines()
assert lines[0] == 'digraph "call graph" {'
assert lines[-1] == "}"
# External node renders dashed; jmp edge renders dashed.
assert '  "0xFFEE" [label="oswrch", style=dashed, color=gray];' in lines, lines
assert '  "0x9000" -> "0xFFEE" [style=dashed];' in lines
assert '  "0x8000" -> "0x8050";' in lines
assert dot.endswith("\n")

# Errors and chaining.
try:
    g.add_node("0x8000")
    raise AssertionError("expected ValueError")
except ValueError:
    pass
try:
    g.add_edge("nope", "0x8000")
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    g.add_edge("0x8000", "0x8050", "bra")
    raise AssertionError("expected ValueError")
except ValueError:
    pass

print("asyoulikeit 10 ref OK")
