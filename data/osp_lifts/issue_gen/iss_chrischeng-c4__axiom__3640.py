"""chrischeng-c4/axiom#3640 — Phase A opaque-value boundary inventory gate."""

from __future__ import annotations

from collections import deque

SITE_KINDS = frozenset({
    "producer",
    "consumer",
    "registry",
    "classifier",
    "private_metadata",
    "python_numeric",
})
DISPOSITIONS = frozenset({
    "legacy_debt",
    "typed_token",
    "private_only",
    "python_numeric",
})


def build_flow_graph(
    site_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> dict[str, list[str]]:
    adj: dict[str, list[str]] = {s: [] for s in site_ids}
    for src, dst in depends_edges:
        if src in adj and dst in adj:
            adj[src].append(dst)
    return adj


def downstream_reach(
    adj: dict[str, list[str]],
    seeds: list[str],
    *,
    site_kinds: dict[str, str] | None = None,
    target_kinds: frozenset[str] | None = None,
) -> list[str]:
    kinds = site_kinds or {}
    targets = target_kinds or frozenset()
    known = {s for s in seeds if s in adj}
    seen: set[str] = set()
    queue: deque[str] = deque()
    for seed in known:
        for nxt in adj[seed]:
            queue.append(nxt)
    hits: list[str] = []
    while queue:
        cur = queue.popleft()
        if cur in seen or cur in known:
            continue
        seen.add(cur)
        kind = kinds.get(cur, "")
        if not targets or kind in targets:
            hits.append(cur)
        for nxt in adj[cur]:
            queue.append(nxt)
    return sorted(hits)


def parent_route_chain(parent_of: dict[str, str], site: str) -> list[str]:
    chain: list[str] = []
    cur = site
    on_path: set[str] = {site}
    while cur in parent_of:
        nxt = parent_of[cur]
        if nxt in on_path:
            break
        on_path.add(nxt)
        chain.append(nxt)
        cur = nxt
    return chain


def load_ledger(
    discovered: list[str],
    rows: dict[str, dict],
) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for sid in discovered:
        if sid in rows:
            out[sid] = dict(rows[sid])
        else:
            out[sid] = {"disposition": "needs_classification"}
    return out


def audit_inventory(
    adj: dict[str, list[str]],
    discovered: list[str],
    ledger: dict[str, dict],
    site_kinds: dict[str, str],
    *,
    mode: str = "inventory",
    stale: frozenset[str] | None = None,
    covered_files: frozenset[str] | None = None,
    source_files: list[str] | None = None,
) -> list[str]:
    stale_set = stale or frozenset()
    covered = covered_files or frozenset()
    files = source_files or []
    diag: list[str] = []

    for sid in sorted(discovered):
        row = ledger.get(sid, {})
        disp = row.get("disposition", "needs_classification")
        if disp == "needs_classification":
            diag.append(f"unclassified:{sid}")
        if sid in stale_set:
            diag.append(f"stale_row:{sid}")
        kind = site_kinds.get(sid, row.get("kind", ""))
        if kind == "producer" and disp == "python_numeric":
            diag.append(f"producer_misclassified_numeric:{sid}")
        if kind == "private_metadata" and row.get("reified", False):
            diag.append(f"private_reified:{sid}")

    for sid, kind in site_kinds.items():
        if kind == "classifier" and sid.startswith("as_int"):
            if not ledger.get(sid, {}).get("parent_route"):
                consumers = downstream_reach(
                    adj,
                    [sid],
                    site_kinds=site_kinds,
                    target_kinds=frozenset({"consumer", "registry"}),
                )
                if consumers:
                    diag.append(f"as_int_without_route:{sid}")

    for fp in sorted(files):
        if fp not in covered:
            diag.append(f"uncovered_file:{fp}")

    legacy = sum(
        1
        for sid in discovered
        if ledger.get(sid, {}).get("disposition") == "legacy_debt"
    )
    if mode == "typed_only" and legacy > 0:
        diag.append("legacy_debt_blocks_typed_token")

    return sorted(diag)
