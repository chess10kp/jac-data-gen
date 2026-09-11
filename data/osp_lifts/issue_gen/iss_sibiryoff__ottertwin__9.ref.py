import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_ottertwin_9",
    Path(__file__).with_name("iss_sibiryoff__ottertwin__9.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_fs_tree(
    ["/src", "/src/a", "/src/a/file.txt", "/src/b"],
    {"/src": True, "/src/a": True, "/src/a/file.txt": False, "/src/b": False},
    [
        ("/src", None),
        ("/src/a", "/src"),
        ("/src/a/file.txt", "/src/a"),
        ("/src/b", "/src"),
    ],
)
plan = mod.plan_copy(store, "/src")
assert plan == ["/src", "/src/a", "/src/a/file.txt", "/src/b"]
assert mod.collect_files(store, "/src") == ["/src/a/file.txt", "/src/b"]
assert mod.plan_copy(store, "/src/a/file.txt") == ["/src/a/file.txt"]
print("ok")
