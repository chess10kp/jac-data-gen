import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_core_9515",
    Path(__file__).with_name("iss_JesusFilm__core__9515.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

s = mod.load_video_store(
    ["series", "season", "episode"],
    {"series": None, "season": "series", "episode": "season"},
    {"series": ["en"], "season": ["es"], "episode": ["fr", "de"]},
)
assert mod.get_available(s, "series") == ["de", "en", "es", "fr"]
assert mod.get_available(s, "season") == ["de", "es", "fr"]

changed = mod.remove_child(s, "season", "episode")
assert "season" in changed
assert mod.get_available(s, "season") == ["es"]
print("ok")
