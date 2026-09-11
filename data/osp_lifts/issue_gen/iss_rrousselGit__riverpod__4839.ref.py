"""Reference harness for iss_rrousselGit__riverpod__4839."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_rrousselGit__riverpod__4839.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
from iss_rrousselGit__riverpod__4839 import (
    has_path,
    make_diamond_graph,
    make_sandbox_graph,
    reachable_sorted,
    sdk_handshake_hangs,
)

nodes = make_sandbox_graph()
assert has_path('riverpod_lint', 'analysis_server_plugin', nodes)

nodes = make_sandbox_graph()
got = reachable_sorted('riverpod_lint', nodes)
expect = ['analysis_server_plugin', 'analyzer', 'riverpod_analyzer_utils']
assert got == expect

nodes = make_diamond_graph()
got = reachable_sorted('riverpod_lint', nodes)
assert len(got) == 3
assert got == ['analysis_server_plugin', 'analyzer', 'riverpod_analyzer_utils']

nodes = make_sandbox_graph()
got = reachable_sorted('not_in_sandbox', nodes)
assert got == []

assert sdk_handshake_hangs('3.12.2', '3.1.8') is True
assert sdk_handshake_hangs('3.13.0-beta', '3.1.8') is False
print("iss_rrousselGit__riverpod__4839 ref OK")
