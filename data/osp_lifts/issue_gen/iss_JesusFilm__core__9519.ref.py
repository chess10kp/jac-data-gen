"""Reference harness for iss_JesusFilm__core__9519."""
import importlib.util
from pathlib import Path
_spec = importlib.util.spec_from_file_location("_mod", Path(__file__).with_name("iss_JesusFilm__core__9519.py"))
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
store = _mod.make_store()
_mod.add_video(store, "parent", None, "container", {"en"})
_mod.add_video(store, "child1", "parent", "variant", {"es"})
_mod.add_video(store, "child2", "parent", "variant", {"fr"})
assert _mod.recompute_available(store, "parent") == {"en", "es", "fr"}
# create empty parent variant
store2 = _mod.make_store()
_mod.add_video(store2, "p", None, "container", {"en"})
vid = _mod.create_empty_parent_variant(store2, "p")
assert vid == "p::variant"
assert _mod.available_languages(store2, "p") == ["en"]
# cleanup removes empty
removed = _mod.check_and_remove_empty_parent_variant(store2, "p::variant")
assert removed is True
assert "p::variant" not in store2.videos
# non-empty not removed
store3 = _mod.make_store()
_mod.add_video(store3, "p2", None, "container", {"en"})
_mod.add_video(store3, "v", "p2", "variant", {"de"})
assert _mod.check_and_remove_empty_parent_variant(store3, "v") is False
# uses shared lookup: scalar childIds would disagree if label not container
store4 = _mod.make_store()
_mod.add_video(store4, "not_container", None, "leaf", {"en"})
_mod.add_video(store4, "c", "not_container", "variant", set())
# c's parent is not container, so lookup returns None -> not removed
assert _mod._shared_parent_lookup(store4, "c") is None
assert _mod.check_and_remove_empty_parent_variant(store4, "c") is False
# diamond-like parent closure order independent
store5 = _mod.make_store()
_mod.add_video(store5, "root", None, "container", set())
_mod.add_video(store5, "a", "root", "variant", {"en"})
_mod.add_video(store5, "b", "root", "variant", {"es"})
assert _mod.recompute_available(store5, "root") == {"en", "es"}
print("iss_JesusFilm__core__9519 ref OK")
