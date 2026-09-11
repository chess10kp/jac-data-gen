import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

s = mod.load_languages(
    ["en", "es", "fr", "de"],
    [("es", "en"), ("fr", "en"), ("de", "fr")],
)
s._available["en"] = False
assert s.recompute_available() >= 2
assert s.available_for("es") is False
assert s.available_for("de") is False
assert s.available_for("missing") is False
print("ok")
