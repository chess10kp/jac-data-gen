"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__7949."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__7949.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
W = _mod.load_compiler_cache_world(
    ["iface", "impl", "ir", "obj", "hover"],
    [
        ("ir", "iface"),
        ("ir", "impl"),
        ("obj", "ir"),
        ("hover", "obj"),
    ],
    {
        "iface": "ki",
        "impl": "km",
        "ir": "kir",
        "obj": "ko",
        "hover": "kh",
    },
    {
        "iface": "di",
        "impl": "dm",
        "ir": "dir",
        "obj": "do",
        "hover": "dh",
    },
)

assert _mod.dependency_closure(W, "hover") == ["hover", "iface", "impl", "ir", "obj"]
assert _mod.dependency_closure(W, "iface") == ["iface"]
assert _mod.dependency_closure(W, "ghost") == []

assert _mod.invalidation_closure(W, ["impl"]) == ["hover", "impl", "ir", "obj"]
assert _mod.invalidation_closure(W, ["iface"]) == ["hover", "iface", "ir", "obj"]
assert _mod.invalidation_closure(W, ["ghost"]) == []
assert _mod.invalidation_closure(W, []) == []

ADV = _mod.load_compiler_cache_world(
    ["root", "left", "right", "join", "prov"],
    [
        ("join", "right"),
        ("join", "left"),
        ("left", "root"),
        ("right", "root"),
        ("prov", "join"),
    ],
    {
        "root": "k0",
        "left": "k1",
        "right": "k1",
        "join": "k2",
        "prov": "k3",
    },
    {
        "root": "d0",
        "left": "d1",
        "right": "d1",
        "join": "d2",
        "prov": "d3",
    },
)
assert _mod.invalidation_closure(ADV, ["root"]) == ["join", "left", "prov", "right", "root"]
assert _mod.dependency_closure(ADV, "prov") == ["join", "left", "prov", "right", "root"]

CYC = _mod.load_compiler_cache_world(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
    {"a": "ka", "b": "kb", "c": "kc"},
    {"a": "da", "b": "db", "c": "dc"},
)
assert _mod.invalidation_closure(CYC, ["a"]) == ["a", "b", "c"]
assert _mod.dependency_closure(CYC, "a") == ["a", "b", "c"]

assert _mod.checkpoint_status(W, ["hover"], dict(W.keys)) == {
    "hover": "adopt",
    "iface": "adopt",
    "impl": "adopt",
    "ir": "adopt",
    "obj": "adopt",
}

changed = dict(W.keys)
changed["impl"] = "km2"
assert _mod.checkpoint_status(W, ["hover"], changed) == {
    "hover": "adopt",
    "iface": "adopt",
    "impl": "recompute",
    "ir": "adopt",
    "obj": "adopt",
}

BAD = _mod.load_compiler_cache_world(
    ["iface", "impl", "ir", "obj", "hover"],
    [
        ("ir", "iface"),
        ("ir", "impl"),
        ("obj", "ir"),
        ("hover", "obj"),
    ],
    dict(W.keys),
    {"iface": "di", "impl": "dm", "ir": "dir", "obj": "do", "hover": ""},
)
assert _mod.checkpoint_status(BAD, ["hover"], dict(W.keys))["hover"] == "quarantine"

assert _mod.corruption_fallback(decode_ok=True, digest_ok=True, schema_ok=True) == "adopt"
assert _mod.corruption_fallback(decode_ok=False, digest_ok=True, schema_ok=True) == "quarantine"
assert _mod.corruption_fallback(decode_ok=True, digest_ok=False, schema_ok=True) == "quarantine"
assert _mod.corruption_fallback(decode_ok=True, digest_ok=True, schema_ok=False) == "cold"

inv = _mod.invalidation_closure(W, ["impl"])
assert _mod.provider_is_current(W, "hover", inv) is False
assert _mod.provider_is_current(W, "iface", inv) is True
assert _mod.provider_is_current(W, "ghost", inv) is False

live = {"iface": "v1", "impl": "v2", "ir": "v3", "obj": "v4", "hover": "v5"}
got = _mod.bust_live_cache(W, ["impl"], live)
assert got == ["hover", "impl", "ir", "obj"]
assert live == {"iface": "v1"}
print("iss_EffortlessMetrics__perl-lsp-swarm__7949 ref OK")
