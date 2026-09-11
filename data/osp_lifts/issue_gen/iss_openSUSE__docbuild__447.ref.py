"""Reference harness for iss_openSUSE__docbuild__447."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_openSUSE__docbuild__447.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
INCLUDES = [
    ("dc:guide.xml", "guide.adoc"),
    ("guide.adoc", "shared.xml"),
    ("guide.adoc", "images/logo.png"),
    ("dc:ref.xml", "ref.adoc"),
    ("ref.adoc", "shared.xml"),
    ("dc:diamond.xml", "right.adoc"),
    ("dc:diamond.xml", "left.adoc"),
    ("right.adoc", "shared.xml"),
    ("left.adoc", "shared.xml"),
]

FINGERPRINTS = {
    "dc:guide.xml": "fp_root_guide",
    "guide.adoc": "fp_guide",
    "shared.xml": "fp_shared_v1",
    "images/logo.png": "fp_logo",
    "dc:ref.xml": "fp_root_ref",
    "ref.adoc": "fp_ref",
    "dc:diamond.xml": "fp_root_diamond",
    "left.adoc": "fp_left",
    "right.adoc": "fp_right",
}

store = _mod.make_store(INCLUDES, FINGERPRINTS)

assert _mod.transitive_deps(store, "dc:guide.xml") == [
    "guide.adoc",
    "images/logo.png",
    "shared.xml",
]
assert _mod.transitive_deps(store, "dc:ref.xml") == ["ref.adoc", "shared.xml"]
assert _mod.transitive_deps(store, "dc:diamond.xml") == [
    "left.adoc",
    "right.adoc",
    "shared.xml",
]
assert _mod.transitive_deps(store, "missing.xml") == []
assert _mod.transitive_deps(store, "dc:guide.xml") == [
    "guide.adoc",
    "images/logo.png",
    "shared.xml",
]

guide_fp = _mod.dependency_fingerprint(store, "dc:guide.xml")
assert guide_fp == (
    "guide.adoc:fp_guide|images/logo.png:fp_logo|shared.xml:fp_shared_v1"
)

assert _mod.get_cached_metadata(store, "dc:guide.xml") is None

calls: list[str] = []


def _runner(dc: str) -> dict:
    calls.append(dc)
    payloads = {
        "dc:guide.xml": {"title": "User Guide", "format": "html"},
        "dc:ref.xml": {"title": "Reference", "format": "pdf"},
        "dc:diamond.xml": {"title": "Diamond", "format": "html"},
    }
    return dict(payloads[dc])


meta = _mod.resolve_metadata(store, "dc:guide.xml", _runner)
assert meta == {"title": "User Guide", "format": "html"}
assert calls == ["dc:guide.xml"]
assert _mod.get_cached_metadata(store, "dc:guide.xml") == {
    "title": "User Guide",
    "format": "html",
}
assert _mod.list_deliverables(store) == ["dc:guide.xml"]

calls.clear()
meta2 = _mod.resolve_metadata(store, "dc:guide.xml", _runner)
assert meta2 == {"title": "User Guide", "format": "html"}
assert calls == []

hit_store = _mod.make_store(
    INCLUDES,
    FINGERPRINTS,
    {
        "dc:ref.xml": {
            "metadata": {"title": "Cached Ref", "format": "pdf"},
            "deps": ["ref.adoc", "shared.xml"],
            "fingerprint": (
                "ref.adoc:fp_ref|shared.xml:fp_shared_v1"
            ),
        }
    },
)
assert _mod.get_cached_metadata(hit_store, "dc:ref.xml") == {
    "title": "Cached Ref",
    "format": "pdf",
}
calls.clear()
assert _mod.resolve_metadata(hit_store, "dc:ref.xml", _runner) == {
    "title": "Cached Ref",
    "format": "pdf",
}
assert calls == []

stale_store = _mod.make_store(
    INCLUDES,
    FINGERPRINTS,
    {
        "dc:ref.xml": {
            "metadata": {"title": "Stale", "format": "pdf"},
            "deps": ["ref.adoc", "shared.xml"],
            "fingerprint": "stale-fingerprint",
        }
    },
)
assert _mod.get_cached_metadata(stale_store, "dc:ref.xml") is None
calls.clear()
assert _mod.resolve_metadata(stale_store, "dc:ref.xml", _runner) == {
    "title": "Reference",
    "format": "pdf",
}
assert calls == ["dc:ref.xml"]

mut_store = _mod.make_store(INCLUDES, FINGERPRINTS)
_mod.resolve_metadata(mut_store, "dc:diamond.xml", _runner)
calls.clear()
mut_store["fingerprints"]["shared.xml"] = "fp_shared_v2"
assert _mod.resolve_metadata(mut_store, "dc:diamond.xml", _runner) == {
    "title": "Diamond",
    "format": "html",
}
assert calls == ["dc:diamond.xml"]

assert _mod.invalidate_cache(store, "nope.xml") is False
assert _mod.invalidate_cache(store, "dc:guide.xml") is True
assert _mod.get_cached_metadata(store, "dc:guide.xml") is None
assert _mod.list_deliverables(store) == []

try:
    _mod.resolve_metadata(store, "missing.xml", _runner)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
print("iss_openSUSE__docbuild__447 ref OK")
