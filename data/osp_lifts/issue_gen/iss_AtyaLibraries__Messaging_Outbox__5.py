"""AtyaLibraries/Messaging.Outbox#5 — relay dependency claim, backoff, and lineage audit."""

from __future__ import annotations

from collections import deque


class OutboxStore:
    def __init__(self) -> None:
        self._messages: dict[str, dict] = {}
        self._depends: dict[str, list[str]] = {}
        self._claims: dict[str, str] = {}


def load_outbox_store(
    messages: list[tuple[str, str, int, str]],
    depends: list[tuple[str, str]],
    next_attempt: dict[str, int] | None = None,
) -> OutboxStore:
    store = OutboxStore()
    sched = next_attempt or {}
    for mid, contract, schema, status in messages:
        store._messages[mid] = {
            "contract": contract,
            "schema": schema,
            "status": status,
            "next_attempt": sched.get(mid, 0),
            "attempt": 0,
            "diag": "",
        }
        store._depends.setdefault(mid, [])
    for msg, prereq in depends:
        if msg in store._messages and prereq in store._messages:
            if prereq not in store._depends[msg]:
                store._depends[msg].append(prereq)
    return store


def prerequisite_closure(store: OutboxStore, message_id: str) -> list[str]:
    if message_id not in store._messages:
        return []
    claimed: set[str] = {message_id}
    work: deque[str] = deque([message_id])
    hits: list[str] = []
    while work:
        cur = work.popleft()
        for prereq in sorted(store._depends.get(cur, [])):
            if prereq not in claimed:
                claimed.add(prereq)
                work.append(prereq)
                hits.append(prereq)
    return sorted(hits)


def dependency_paths(
    store: OutboxStore,
    source: str,
    target: str,
    max_depth: int = 8,
) -> list[list[str]]:
    if source not in store._messages or target not in store._messages:
        return []
    stack: list[tuple[str, list[str]]] = [(source, [source])]
    out: list[list[str]] = []
    while stack:
        node, trail = stack.pop()
        if node == target:
            if len(trail) > 1:
                out.append(trail)
            continue
        if len(trail) >= max_depth:
            continue
        for prereq in sorted(store._depends.get(node, [])):
            if prereq not in trail:
                stack.append((prereq, trail + [prereq]))
    return sorted(out)


def blocked_by(store: OutboxStore, message_id: str) -> list[str]:
    if message_id not in store._messages:
        return []
    out: list[str] = []
    for prereq in sorted(store._depends.get(message_id, [])):
        if store._messages[prereq]["status"] != "published":
            out.append(prereq)
    return out


def stable_identity(store: OutboxStore, message_id: str) -> tuple[str, int]:
    row = store._messages.get(message_id)
    if row is None:
        return ("", 0)
    return (row["contract"], row["schema"])


def claimable_ids(
    store: OutboxStore,
    owner: str,
    tick: int,
    limit: int = 10,
) -> list[str]:
    out: list[str] = []
    for mid in sorted(store._messages):
        row = store._messages[mid]
        if row["status"] != "pending":
            continue
        if row["next_attempt"] > tick:
            continue
        holder = store._claims.get(mid)
        if holder is not None:
            continue
        if blocked_by(store, mid):
            continue
        out.append(mid)
        if len(out) >= limit:
            break
    return out


def claim_batch(
    store: OutboxStore,
    owner: str,
    message_ids: list[str],
    tick: int,
) -> list[str]:
    claimed: list[str] = []
    for mid in sorted(message_ids):
        if mid not in store._messages:
            continue
        row = store._messages[mid]
        if row["status"] != "pending" or row["next_attempt"] > tick:
            continue
        holder = store._claims.get(mid)
        if holder is not None:
            continue
        if blocked_by(store, mid):
            continue
        store._claims[mid] = owner
        claimed.append(mid)
    return claimed


def record_failure(
    store: OutboxStore,
    message_id: str,
    tick: int,
    diag: str,
) -> int:
    row = store._messages.get(message_id)
    if row is None:
        return -1
    row["attempt"] += 1
    delay = min(2 ** row["attempt"], 64)
    row["next_attempt"] = tick + delay
    row["status"] = "failed"
    row["diag"] = diag[:120]
    store._claims.pop(message_id, None)
    return row["next_attempt"]
