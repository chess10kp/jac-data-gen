"""Demand-driven incremental recomputation for context packs.

When a file changes, the pack layer must decide what to recompute.
Rebuild-everything is too slow; skip-too-much serves stale results.
The Adapton/Salsa model fixes both: mark dependents dirty LAZILY (a BFS
sweep from the changed nodes through the dependency graph -- no
recomputation yet), recompute only when the value is demanded, and
apply EARLY CUTOFF: when a recomputed result hash is identical to the
stored one, the dirty mark stops propagating downstream -- a body that
is reformatted but semantically identical dirties nothing beyond
itself, and unqueried dirty packs simply stay dirty until needed.

Packs are kept as an adjacency map (pack id -> the packs it depends on)
plus a results map of stored content hashes. ``mark_dirty`` is the lazy
BFS closure over the reverse adjacency. ``recompute`` is demand-driven
settlement: a dirty pack first settles its own dirty dependencies
(they must hold their final hashes before anything downstream derives
from them), then derives its new hash -- a changed source pack hashes
as ``src:<id>``; a derived pack hashes over its sorted dependency
hashes -- and either lands in ``cleaned`` (identical hash: cutoff, no
dependent settles through it) or in ``recomputed`` and propagates the
demand to its still-unsettled dirty dependents. ``results`` is never
mutated.
Ref: nateschmiedehaus/LiBrainian#93
"""


def _dependents(graph):
    """pack -> the packs that depend on it (reverse adjacency)."""
    rev = {}
    for pack, deps in graph.items():
        for d in deps:
            rev.setdefault(d, []).append(pack)
    return rev


def mark_dirty(graph, changed):
    """Sorted ids of every pack dirtied by ``changed`` (BFS closure).

    Changed ids that appear nowhere in the graph are ignored; a shared
    dependency reached via two paths dirties once.
    """
    rev = _dependents(graph)
    known = set(graph)
    for deps in graph.values():
        known.update(deps)
    seen = set()
    queue = [c for c in changed if c in known]
    while queue:
        cur = queue.pop(0)
        if cur in seen:
            continue  # diamond confluence: dirty once, not once per path
        seen.add(cur)
        queue.extend(rev.get(cur, []))
    return sorted(seen)


def _derived(pack, deps, results):
    parts = ",".join(f"{d}={results.get(d, '')}" for d in sorted(deps))
    return f"f:{pack}({parts})"


def recompute(graph, results, changed):
    """Demand-driven recompute with early cutoff.

    Returns {"recomputed": sorted ids whose stored hash changed,
    "cleaned": sorted ids whose recomputation matched the stored hash
    (the cutoff fired -- propagation stopped there)}. Packs dirtied
    only upstream of a cutoff stay dirty and appear in neither list.
    """
    cur = dict(results)
    rev = _dependents(graph)
    dirty = set(mark_dirty(graph, changed))
    chset = set(changed)
    settled = set()
    recomputed = set()
    cleaned = set()

    def settle(pack):
        if pack in settled:
            return
        settled.add(pack)
        for dep in sorted(graph.get(pack, [])):
            if dep in dirty and dep not in settled:
                settle(dep)
        if pack in chset:
            new = f"src:{pack}"
        else:
            new = _derived(pack, graph.get(pack, []), cur)
        if new == cur.get(pack):
            cleaned.add(pack)  # early cutoff: no dependent settles via me
        else:
            cur[pack] = new
            recomputed.add(pack)
            for dependent in sorted(rev.get(pack, [])):
                if dependent in dirty and dependent not in settled:
                    settle(dependent)

    for c in sorted(chset):
        if c in graph:
            settle(c)
    return {"recomputed": sorted(recomputed), "cleaned": sorted(cleaned)}
