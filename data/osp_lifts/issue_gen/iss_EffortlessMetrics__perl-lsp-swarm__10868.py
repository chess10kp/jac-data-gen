"""Synthetic before-code for EffortlessMetrics/perl-lsp-swarm#10868.

Project exact owner-to-target liveness edges from canonical reference
occurrences using hand-rolled adjacency and queue-walk machinery.
"""

from __future__ import annotations

from collections import deque
from typing import Any

BLOCKED_SOURCES = frozenset({"ref-source", "name-derived", "compat-projection"})
ADMITTED_KINDS = frozenset(
    {
        "direct_call",
        "qualified_call",
        "static_method",
        "coderef_capture",
        "import_alias",
        "typeglob_alias",
    }
)


def _build_adj(edges: list[dict[str, Any]]) -> dict[str, list[str]]:
    adj: dict[str, list[str]] = {}
    for edge in edges:
        adj.setdefault(edge["owner"], []).append(edge["target"])
    return adj


def is_blocked_source(source_kind: str) -> bool:
    return source_kind in BLOCKED_SOURCES


def _exact_projection_allowed(occ: dict[str, Any], facts: dict[str, dict[str, Any]]) -> bool:
    owner = facts.get(occ.get("owner_id", ""))
    target = facts.get(occ.get("target_id", ""))
    if owner is None or target is None:
        return False
    gen = occ.get("generation", 0)
    if gen < owner.get("generation", 0) or gen < target.get("generation", 0):
        return False
    root = occ.get("root_id")
    return root == owner.get("root_id") and root == target.get("root_id")


def project_exact_edges(
    occurrences: list[dict[str, Any]],
    facts: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    projected: list[dict[str, Any]] = []
    for occ in occurrences:
        if is_blocked_source(occ.get("source_kind", "")):
            continue
        kind = occ.get("kind", "")
        if kind not in ADMITTED_KINDS:
            continue
        if not _exact_projection_allowed(occ, facts):
            continue
        owner = facts[occ["owner_id"]]
        target = facts[occ["target_id"]]
        projected.append(
            {
                "owner": owner["exec_id"],
                "target": target["exec_id"],
                "kind": kind,
                "occurrence_id": occ["occurrence_id"],
                "root": owner["root_id"],
                "generation": occ["generation"],
                "source_kind": occ.get("source_kind", "canonical"),
            }
        )
    return projected


def canonical_edge_set(edges: list[dict[str, Any]]) -> list[tuple[Any, ...]]:
    keys: list[tuple[Any, ...]] = []
    for edge in edges:
        keys.append(
            (
                edge["owner"],
                edge["target"],
                edge["kind"],
                edge["occurrence_id"],
                edge["root"],
                edge["generation"],
                edge["source_kind"],
            )
        )
    return sorted(keys)


def liveness_closure(root_owner: str, edges: list[dict[str, Any]]) -> set[str]:
    adj = _build_adj(edges)
    claimed: dict[str, bool] = {}
    frontier: deque[str] = deque([root_owner])
    live: set[str] = {root_owner}
    claimed[root_owner] = True
    while frontier:
        current = frontier.popleft()
        for nxt in adj.get(current, []):
            live.add(nxt)
            if claimed.get(nxt):
                continue
            claimed[nxt] = True
            frontier.append(nxt)
    return live
