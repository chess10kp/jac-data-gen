"""EffortlessMetrics/perl-lsp-swarm#12317 -- compiler_static_project cutline receipt.

One exact candidate binds imported local-lexical profile with production
compiler-world, navigation, rename, representative-project and work
evidence into one deterministic compiler_static_project_cutline.v1 packet.
"""

from __future__ import annotations

from collections import deque

STALE = "stale"
PASS = "pass"
FAILED = "failed"
NOT_PROVEN = "not_proven"

def _binding_key(candidate: dict) -> tuple:
    return (
        candidate.get("sha"),
        candidate.get("profile_digest"),
        candidate.get("root_generation"),
        candidate.get("toolchain"),
    )

def _all_receipts_current(receipts: list[dict], candidate_key: tuple) -> bool:
    for r in receipts:
        if _binding_key(r.get("candidate", {})) != candidate_key:
            return False
        if r.get("status") in (STALE, NOT_PROVEN):
            return False
        if not r.get("current", True):
            return False
    return True

def evaluate_cutline(candidate: dict, receipts: list[dict], limitations: list[str]) -> dict:
    # hand-rolled adjacency for dependency between receipts (depends graph)
    adj: dict[str, list[str]] = {}
    nodes: set[str] = set()
    for r in receipts:
        rid = r.get("id", "")
        nodes.add(rid)
        adj.setdefault(rid, [])
        for dep in r.get("depends_on", []):
            adj.setdefault(dep, []).append(rid)
            nodes.add(dep)
    # BFS from any failed node to see propagation (queue walk)
    failed = {r["id"] for r in receipts if r.get("verdict") == FAILED}
    q: deque[str] = deque(failed)
    seen: set[str] = set(failed)
    while q:
        cur = q.popleft()
        for nxt in adj.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    key = _binding_key(candidate)
    if not receipts:
        verdict = NOT_PROVEN
    elif not _all_receipts_current(receipts, key):
        verdict = NOT_PROVEN
    elif failed:
        verdict = FAILED
    else:
        # check all required groups present
        required = {"local_lexical", "world_currentness", "world_navigation", "world_rename", "representative", "correctness"}
        present = {r.get("group", "") for r in receipts}
        if not required.issubset(present):
            verdict = NOT_PROVEN
        elif limitations:
            verdict = PASS
        else:
            verdict = PASS
    return {
        "candidate_key": key,
        "verdict": verdict,
        "failed_closure": sorted(seen),
        "limitations": sorted(limitations),
        "receipt_ids": sorted(nodes),
    }

def claim_ceiling(packet: dict) -> str:
    if packet.get("verdict") != PASS:
        return "none"
    if packet.get("limitations"):
        return "static_project_limited"
    return "static_project"

def has_cross_candidate_mixing(packets: list[dict]) -> bool:
    keys = {_binding_key(p.get("candidate", {})) for p in packets}
    return len(keys) > 1

def is_deterministic(r1: dict, r2: dict) -> bool:
    return r1.get("candidate_key") == r2.get("candidate_key") and r1.get("verdict") == r2.get("verdict")
