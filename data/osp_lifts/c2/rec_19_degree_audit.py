"""University degree auditor: which courses does a finished set unlock?

Courses form an adjacency dict of course code -> list of course codes it
unlocks (passing a prerequisite unlocks follow-ups). The auditor floods
forward from every completed course with one shared deque walk.
"""
from collections import deque


def build_catalog(codes, unlocks):
    """Adjacency dict; unlocks are directed (prereq, followup) pairs."""
    cat = {c: [] for c in codes}
    for pre, post in unlocks:
        cat[pre].append(post)
    return cat


def unlocked_by(cat, done):
    """Courses reachable forward from any code in ``done``, excluding the
    done set itself (sorted). Unknown codes in ``done`` are ignored."""
    valid = [c for c in done if c in cat]
    seen = set(valid)
    queue = deque(valid)
    while queue:
        cur = queue.popleft()
        for nxt in cat[cur]:
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen - set(done))


def direct_unlocks(cat, code):
    """Courses unlocked immediately by passing ``code`` (sorted)."""
    if code not in cat:
        return []
    return sorted(cat[code])
