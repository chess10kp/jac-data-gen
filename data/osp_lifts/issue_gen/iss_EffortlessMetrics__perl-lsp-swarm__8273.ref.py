"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__8273."""
import importlib.util
from pathlib import Path
_spec = importlib.util.spec_from_file_location("_mod", Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__8273.py"))
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
m = _mod.PositionMapper("utf-16")
m.add_line("hello")
m.add_line("world")
assert _mod.line_col_to_offset(m, 0, 0) == 0
assert _mod.line_col_to_offset(m, 0, 5) == 5
assert _mod.line_col_to_offset(m, 1, 0) == 6
assert _mod.offset_to_line_col(m, 0) == (0, 0)
assert _mod.offset_to_line_col(m, 6) == (1, 0)
assert _mod.is_valid_boundary(m, 0, 2) is True
assert _mod.is_valid_boundary(m, 0, 100) is False
assert _mod.is_valid_boundary(m, 5, 0) is False
# generation increments
g0 = _mod.mapper_generation(m)
m.add_line("extra")
assert _mod.mapper_generation(m) == g0 + 1
# ordering independent for generation? not needed
# utf-8 vs utf-16 same ascii
m2 = _mod.PositionMapper("utf-8")
m2.add_line("abc")
assert _mod.line_col_to_offset(m2, 0, 1) == 1
# invalid encoding
try:
    _mod.PositionMapper("utf-32")
    assert False
except ValueError:
    assert True
# offset out of range
assert _mod.offset_to_line_col(m, -1) is None
assert _mod.offset_to_line_col(m, 1000) is None
print("iss_EffortlessMetrics__perl-lsp-swarm__8273 ref OK")
