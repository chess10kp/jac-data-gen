"""Curriculum prerequisite-graph validation and route totals.

sora-kisaragi/ai-open-textbook#74: the curriculum JSON is the authoritative
source for lesson timing and prerequisite edges; automated checks must prove
the data resolves to an acyclic prerequisite graph, that every referenced
prerequisite exists, and that the mandatory route's period totals hold.
The checker hand-rolls an adjacency dict of lesson -> [prerequisite lessons]
and validates it with explicit frontier loops. Results are validity flags,
sorted sets, and per-unit period sums -- never a topological sequence.
"""


def build_curriculum(lessons, prereqs):
    """Adjacency dict; lessons are (id, unit, periods) triples and prereqs
    are (lesson_id, required_id) pairs."""
    cur = {}
    for lid, unit, periods in lessons:
        cur[lid] = {"unit": unit, "periods": periods, "needs": []}
    for lid, req in prereqs:
        if lid in cur:
            cur[lid]["needs"].append(req)
    return cur


def has_cycle(cur):
    """True when the prerequisite graph contains a directed cycle."""
    state = {lid: 0 for lid in cur}   # 0 fresh, 1 in-stack, 2 done
    for start in cur:
        if state[start] != 0:
            continue
        stack = [(start, iter(cur[start]["needs"]))]
        state[start] = 1
        while stack:
            node, it = stack[-1]
            advanced = False
            for nxt in it:
                if nxt not in cur:
                    continue
                if state[nxt] == 1:
                    return True
                if state[nxt] == 0:
                    state[nxt] = 1
                    stack.append((nxt, iter(cur[nxt]["needs"])))
                    advanced = True
                    break
            if not advanced:
                state[node] = 2
                stack.pop()
    return False


def missing_prereqs(cur):
    """Sorted (lesson_id, unknown_required_id) pairs."""
    out = []
    for lid in sorted(cur):
        for req in cur[lid]["needs"]:
            if req not in cur:
                out.append((lid, req))
    return out


def unpositioned_lessons(cur):
    """Sorted lesson ids without a positive period allocation."""
    return sorted(lid for lid in cur if cur[lid]["periods"] <= 0)


def prerequisites_of(cur, lesson_id):
    """Transitive prerequisite closure of one lesson (sorted, exclusive)."""
    if lesson_id not in cur:
        return []
    seen = set()
    frontier = list(cur[lesson_id]["needs"])
    while frontier:
        cur_id = frontier.pop()
        if cur_id in seen or cur_id == lesson_id:
            continue
        seen.add(cur_id)
        if cur_id in cur:
            frontier.extend(cur[cur_id]["needs"])
    return sorted(seen)


def unit_totals(cur):
    """Per-unit mandatory period totals as sorted (unit, periods) pairs."""
    totals = {}
    for lid in cur:
        info = cur[lid]
        totals[info["unit"]] = totals.get(info["unit"], 0) + info["periods"]
    return sorted(totals.items())
