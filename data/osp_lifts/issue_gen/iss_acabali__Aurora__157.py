"""acabali/Aurora#157 — canonical operational state tree reachability and reconciliation."""

from collections import deque
from typing import Any

CANONICAL_MAIN = "8b3293d168bd65ad053330e53695d50a73d552ad"
PR194_HEAD = "d96036ff609e0cac98f6c81a9474185e51b4f500"
DETACHED = "3c213f0ea8f005260d90b243b8cac2cb1731833d"


def _fresh_state() -> dict[str, Any]:
    parent: dict[str, str | None] = {
        "repo": None,
        "main": "repo",
        "pr194": "repo",
        "detached": "repo",
        "privacy_suite": "pr194",
        "lead_pipeline": "main",
    }
    children: dict[str, list[str]] = {
        "repo": ["main", "pr194", "detached"],
        "main": ["lead_pipeline"],
        "pr194": ["privacy_suite"],
        "detached": [],
        "privacy_suite": [],
        "lead_pipeline": [],
    }
    status: dict[str, str] = {
        "repo": "PUBLIC",
        "main": "RESIDUAL_PII",
        "pr194": "SOURCE_GATES_GREEN",
        "detached": "TREE_EQUIVALENT",
        "privacy_suite": "10/10_PASS",
        "lead_pipeline": "ACTIVE_EXPOSURE",
    }
    for node in children:
        children[node] = sorted(children[node])
    return {"parent": parent, "children": children, "status": status}


def path_to_root(node_id: str, state: dict[str, Any] | None = None) -> list[str]:
    s = state if state is not None else _fresh_state()
    if node_id not in s["parent"]:
        raise KeyError(node_id)
    path: list[str] = []
    cur: str | None = node_id
    while cur is not None:
        path.append(cur)
        cur = s["parent"][cur]
    path.reverse()
    return path


def reachable_status_nodes(from_id: str, state: dict[str, Any] | None = None) -> list[str]:
    s = state if state is not None else _fresh_state()
    if from_id not in s["children"]:
        raise KeyError(from_id)
    seen: set[str] = set()
    queue: deque[str] = deque([from_id])
    while queue:
        node = queue.popleft()
        if node in seen:
            continue
        seen.add(node)
        queue.extend(s["children"][node])
    return sorted(seen)


def reconciliation_delta(base: str, candidate: str, state: dict[str, Any] | None = None) -> dict[str, Any]:
    s = state if state is not None else _fresh_state()
    base_path = set(path_to_root(base, s))
    cand_path = set(path_to_root(candidate, s))
    return {
        "shared_ancestors": sorted(base_path & cand_path),
        "base_only": sorted(base_path - cand_path),
        "candidate_only": sorted(cand_path - base_path),
        "base_status": s["status"].get(base, "UNKNOWN"),
        "candidate_status": s["status"].get(candidate, "UNKNOWN"),
    }


def blocking_issues(state: dict[str, Any] | None = None) -> list[str]:
    s = state if state is not None else _fresh_state()
    issues: list[str] = []
    if s["status"].get("main") == "RESIDUAL_PII":
        issues.append("main:residual_pii")
    if s["status"].get("lead_pipeline") == "ACTIVE_EXPOSURE":
        issues.append("lead_pipeline:active_exposure")
    if s["status"].get("pr194") == "SOURCE_GATES_GREEN" and s["status"].get("main") != "INTEGRATED":
        issues.append("pr194:not_integrated")
    return sorted(issues)


def canonical_refs(state: dict[str, Any] | None = None) -> dict[str, str]:
    return {
        "main": CANONICAL_MAIN,
        "pr194": PR194_HEAD,
        "detached": DETACHED,
    }
