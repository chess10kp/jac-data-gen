import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_typemd__typemd__374.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_objects(
    [("book1", {"title": "HP"}), ("person1", {"name": "Rowling", "bio": "author"})],
    [("book1", "author", "person1")],
)
assert mod.resolve_field(store, "book1", "author.name") == "Rowling"
assert mod.resolve_field(store, "book1", "author.bio") == "author"
assert mod.resolve_field(store, "book1", "title") == "HP"
assert mod.resolve_field(store, "book1", "author.missing") is None
print("ok")
