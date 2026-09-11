"""Schedule schema invariants: parentId cycles and friends.

``packages/schema/src/schedule.ts`` validates block nesting, but the
``parentId`` check only verified the referenced block exists -- a cycle
(A -> B -> A) slipped through and later sent ``computeOverlapGroups``
and the nested renderer into infinite recursion. The fix adds DFS cycle
detection over the parent links (plus the other invariant checks: blocks
inside the day range, IANA timezone, unique ids, unique byDay entries).
Ref: VECTORG99/Canectt#42
"""

KNOWN_TZ = {"America/Santiago", "UTC", "Europe/Berlin", "Asia/Tokyo"}


def load_schedule(doc):
    """``doc``: {timezone, dayRange:[start,end], recurrence:{byDay:[...]},
    blocks:[{id,parentId,startTime,endTime}]}; returns the schedule."""
    return {
        "timezone": doc["timezone"],
        "dayRange": list(doc["dayRange"]),
        "byDay": list(doc.get("recurrence", {}).get("byDay", [])),
        "blocks": [dict(b) for b in doc["blocks"]],
    }


def _block_cycle(blocks, start):
    """Cycle members along the parent chain from ``start``, or None."""
    chain = []
    seen = set()
    cur = start
    while cur is not None and cur in blocks:
        if cur in seen:
            return chain[chain.index(cur):]
        seen.add(cur)
        chain.append(cur)
        cur = blocks[cur].get("parentId")
    return None


def _index(blocks):
    """id -> block (last wins), mirroring the map the renderer builds."""
    return {b["id"]: b for b in blocks}


def validate(sched):
    """Sorted list of invariant violations (empty when valid)."""
    errors = []
    raw = sched["blocks"]
    blocks = _index(raw)

    ids = [b["id"] for b in raw]
    dupes = sorted({i for i in ids if ids.count(i) > 1})
    for d in dupes:
        errors.append("duplicate id: " + d)

    for b in sorted(raw, key=lambda x: x["id"]):
        pid = b.get("parentId")
        if pid is not None and pid not in blocks:
            errors.append("unknown parent: " + b["id"] + " -> " + pid)

    # Cycle check over parent links, deterministic start order.
    for bid in sorted(blocks):
        cyc = _block_cycle(blocks, bid)
        if cyc:
            errors.append("cycle: " + " -> ".join(cyc + [cyc[0]]))
            break

    lo, hi = sched["dayRange"]
    for b in sorted(raw, key=lambda x: x["id"]):
        if not (lo <= b["startTime"] and b["endTime"] <= hi):
            errors.append("block outside dayRange: " + b["id"])

    seen_days = set()
    for day in sched["byDay"]:
        if day in seen_days:
            errors.append("duplicate byDay: " + day)
        seen_days.add(day)

    if sched["timezone"] not in KNOWN_TZ:
        errors.append("invalid timezone: " + sched["timezone"])

    return sorted(errors)


def subtree(sched, bid):
    """Sorted ids of the nesting subtree rooted at ``bid`` (inclusive)."""
    blocks = _index(sched["blocks"])
    if bid not in blocks:
        return []
    out = []
    stack = [bid]
    seen = set()
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for b in blocks.values():
            if b.get("parentId") == cur:
                stack.append(b["id"])
    return sorted(out)


def nesting_depth(sched, bid):
    """Deepest nesting chain below ``bid`` (0 when unknown or leaf)."""
    blocks = _index(sched["blocks"])
    if bid not in blocks:
        return -1

    def depth(cur):
        kids = [b["id"] for b in blocks.values() if b.get("parentId") == cur]
        if not kids:
            return 0
        return 1 + max(depth(k) for k in kids)

    return depth(bid)
