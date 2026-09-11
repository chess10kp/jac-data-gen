import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_Cacti__cacti__7713",
    Path(__file__).with_name("iss_Cacti__cacti__7713.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
idx = mod.load_index([
    ("", True),
    ("lib", True),
    ("lib/a.php", False),
    ("lib/vendor", True),
    ("lib/vendor/x.php", False),
    ("include", True),
    ("include/b.php", False),
])
assert mod.is_ignored("lib/vendor/x.php", {"lib/vendor"}) is True
assert mod.is_ignored("lib/a.php", {"lib/vendor"}) is False
got = mod.collect_files(idx, "", set())
assert got == ["include/b.php", "lib/a.php", "lib/vendor/x.php"]
assert mod.collect_files(idx, "", {"lib/vendor"}) == ["include/b.php", "lib/a.php"]
assert mod.collect_files(idx, "missing", set()) == []
print("ok")
