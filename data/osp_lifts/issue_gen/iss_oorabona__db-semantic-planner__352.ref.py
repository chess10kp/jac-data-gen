import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_352",
    Path(__file__).with_name("iss_oorabona__db-semantic-planner__352.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

fold = mod.load_branch_metadata(
    [
        [{"js": "bigint"}, {"js": None}],
        [{"js": "bigint"}, {"js": None}],
    ]
)
assert mod.fold_js_read_at(fold, 0) == "bigint"
assert mod.fold_js_read_at(fold, 1) is None
assert mod.fold_js_read_metadata(fold) == ["bigint", None]
assert mod.should_convert(fold, 0) is True
assert mod.should_convert(fold, 1) is False

fold_bad = mod.load_branch_metadata(
    [
        [{"js": "bigint"}, {"js": "number"}],
        [{"js": "number"}, {"js": "number"}],
    ]
)
assert mod.fold_js_read_at(fold_bad, 0) is None
print("ok")
