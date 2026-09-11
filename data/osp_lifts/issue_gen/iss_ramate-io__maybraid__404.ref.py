import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod404",
    Path(__file__).with_name("iss_ramate-io__maybraid__404.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ms = mod.load_mesh(
    ["root", "member_a", "member_b", "sub"],
    [("root", "member_a"), ("root", "member_b"), ("member_a", "sub")],
)
assert mod.descendants(ms, "root") == ["member_a", "member_b", "sub"]
assert mod.validate_no_cycles(ms) is True
assert mod.member_count(ms, "root") == 4
assert mod.member_count(ms, "missing") == 0
print("ok")
