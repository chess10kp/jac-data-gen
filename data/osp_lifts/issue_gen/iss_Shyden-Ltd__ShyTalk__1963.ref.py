"""Reference harness for iss_Shyden-Ltd__ShyTalk__1963."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Shyden-Ltd__ShyTalk__1963.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
load_profile_store = _mod.load_profile_store
downstream_fields = _mod.downstream_fields
depends_path = _mod.depends_path
invalidation_order = _mod.invalidation_order
effective_cohort = _mod.effective_cohort
resolve_profile_state = _mod.resolve_profile_state
read_resolved_cohort = _mod.read_resolved_cohort
session_cache_cohort = _mod.session_cache_cohort
complete_dob_gate = _mod.complete_dob_gate
DEPS = [
    ("effective_cohort", "date_of_birth"),
    ("resolved_cohort", "effective_cohort"),
    ("session_cache", "resolved_cohort"),
    ("preview_overlay", "resolved_cohort"),
]

store = load_profile_store(
    {"50000010": {"date_of_birth": None}},
    DEPS,
)
assert downstream_fields(store, "date_of_birth") == [
    "effective_cohort",
    "preview_overlay",
    "resolved_cohort",
    "session_cache",
]
assert depends_path(store, "date_of_birth", "session_cache") == [
    "date_of_birth",
    "effective_cohort",
    "resolved_cohort",
    "session_cache",
]
assert invalidation_order(store, "date_of_birth") == [
    "effective_cohort",
    "resolved_cohort",
    "preview_overlay",
    "session_cache",
]
assert effective_cohort(None) == "minor"
assert effective_cohort(1995, 2026) == "adult"
assert effective_cohort(2010, 2026) == "minor"

assert resolve_profile_state(store, "50000010", 2026) == "minor"
assert read_resolved_cohort(store, "50000010") == "minor"
assert session_cache_cohort(store, "50000010") == "minor"

assert complete_dob_gate(store, "50000010", 1995, 2026) == "adult"
assert read_resolved_cohort(store, "50000010") == "adult"
assert session_cache_cohort(store, "50000010") == "adult"

store2 = load_profile_store({"u2": {"date_of_birth": None}}, DEPS)
resolve_profile_state(store2, "u2", 2026)
assert complete_dob_gate(store2, "u2", 2000, 2026, refresh_ok=False) is None
assert read_resolved_cohort(store2, "u2") is None
assert session_cache_cohort(store2, "u2") is None

diamond_deps = [
    ("effective_cohort", "date_of_birth"),
    ("resolved_cohort", "effective_cohort"),
    ("session_cache", "resolved_cohort"),
    ("preview_overlay", "resolved_cohort"),
    ("audit_stamp", "session_cache"),
    ("audit_stamp", "preview_overlay"),
]
diamond = load_profile_store({"d1": {"date_of_birth": None}}, diamond_deps)
assert downstream_fields(diamond, "date_of_birth") == [
    "audit_stamp",
    "effective_cohort",
    "preview_overlay",
    "resolved_cohort",
    "session_cache",
]
assert depends_path(diamond, "date_of_birth", "audit_stamp") == [
    "date_of_birth",
    "effective_cohort",
    "resolved_cohort",
    "preview_overlay",
    "audit_stamp",
]
resolve_profile_state(diamond, "d1", 2026)
assert complete_dob_gate(diamond, "d1", 1990, 2026) == "adult"
assert session_cache_cohort(diamond, "d1") == "adult"

assert downstream_fields(store, "missing_field") == []
assert depends_path(store, "missing_field", "session_cache") == []
assert depends_path(store, "date_of_birth", "missing_field") == []
assert resolve_profile_state(store, "ghost", 2026) is None
assert complete_dob_gate(store, "ghost", 1995, 2026) is None
assert read_resolved_cohort(store, "ghost") is None
assert session_cache_cohort(store, "ghost") is None
print("iss_Shyden-Ltd__ShyTalk__1963 ref OK")
print("iss_Shyden-Ltd__ShyTalk__1963 ref OK")
