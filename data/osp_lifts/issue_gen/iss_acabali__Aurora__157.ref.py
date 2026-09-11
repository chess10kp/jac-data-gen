"""Reference harness for iss_acabali__Aurora__157."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_acabali__Aurora__157.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
from iss_acabali__Aurora__157 import (
    CANONICAL_MAIN,
    DETACHED,
    PR194_HEAD,
    blocking_issues,
    canonical_refs,
    path_to_root,
    reachable_status_nodes,
    reconciliation_delta,
)

assert path_to_root("privacy_suite") == ["repo", "pr194", "privacy_suite"]
assert path_to_root("lead_pipeline") == ["repo", "main", "lead_pipeline"]
assert reachable_status_nodes("repo") == sorted(
    ["repo", "main", "pr194", "detached", "privacy_suite", "lead_pipeline"]
)
assert reachable_status_nodes("pr194") == ["pr194", "privacy_suite"]

delta = reconciliation_delta("main", "pr194")
assert delta["shared_ancestors"] == ["repo"]
assert delta["base_only"] == ["main"]
assert delta["candidate_only"] == ["pr194"]
assert delta["base_status"] == "RESIDUAL_PII"
assert delta["candidate_status"] == "SOURCE_GATES_GREEN"

assert blocking_issues() == sorted(
    ["lead_pipeline:active_exposure", "main:residual_pii", "pr194:not_integrated"]
)

refs = canonical_refs()
assert refs["main"] == CANONICAL_MAIN
assert refs["pr194"] == PR194_HEAD
assert refs["detached"] == DETACHED
print("iss_acabali__Aurora__157 ref OK")
