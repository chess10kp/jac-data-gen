import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

BEATS = [
    ("intro", "M:intro_ok"),
    ("route2", "M:route2_ok"),
    ("finale", "M:finale_ok"),
]
REQUIRES = [
    ("route2", "intro"),
    ("finale", "route2"),
]
ENRICH = [
    ("intro", "Narr: intro bloom", "FB: intro steady"),
    ("route2", "Narr: route pulse", "FB: route steady"),
    ("finale", "Narr: finale crest", "FB: finale steady"),
]

store = mod.load_campaign(BEATS, REQUIRES, ENRICH)

assert mod.required_beats(store, "finale") == ["intro", "route2"]
assert mod.downstream_beats(store, "intro") == ["finale", "route2"]
assert mod.truth_snapshot(store, "finale") == "M:finale_ok"

pres, reason, used_fb = mod.present_enrichment(store, "finale", "timeout")
assert pres == "FB: finale steady"
assert reason == "fallback:timeout"
assert used_fb is True
assert mod.truth_snapshot(store, "finale") == "M:finale_ok"

ok_pres, ok_reason, ok_fb = mod.present_enrichment(store, "intro", None)
assert ok_pres == "Narr: intro bloom"
assert ok_reason == "ok"
assert ok_fb is False

assert mod.truth_derived_path(store, "intro") == [
    "M:finale_ok",
    "M:intro_ok",
    "M:route2_ok",
]

for fc in ("unavailable", "refusal", "malformed", "spend_denied"):
    p, r, fb = mod.present_enrichment(store, "route2", fc)
    assert p == "FB: route steady"
    assert r == f"fallback:{fc}"
    assert fb is True
    assert mod.truth_snapshot(store, "route2") == "M:route2_ok"

assert mod.required_beats(store, "missing") == []
assert mod.downstream_beats(store, "missing") == []
assert mod.truth_snapshot(store, "missing") == ""
assert mod.truth_derived_path(store, "missing") == []
unk_pres, unk_reason, unk_fb = mod.present_enrichment(store, "missing", "timeout")
assert unk_pres == ""
assert unk_reason == "unknown_beat"
assert unk_fb is True

diamond = mod.load_campaign(
    ["top", "left", "right", "base", "leaf"],
    [
        ("top", "right"),
        ("base", "leaf"),
        ("top", "left"),
        ("right", "base"),
        ("left", "base"),
    ],
    [("top", "gen", "fb")],
)
assert mod.required_beats(diamond, "top") == ["base", "leaf", "left", "right"]
assert mod.downstream_beats(diamond, "leaf") == ["base", "left", "right", "top"]

print("ok")
