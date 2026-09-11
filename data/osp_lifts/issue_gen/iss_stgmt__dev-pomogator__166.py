"""Forward change-impact analysis over a spec dependency graph.

dev-pomogator stores requirements as a spec graph: ACs reference FRs,
scenarios cover ACs, tasks implement scenarios, and files/tests bind to
tasks -- nine typed edge kinds in all. The shipped trace tooling is
strictly one-hop: ``get_trace`` scans ``graph.edges`` once for direct
references and stops, so answering "what downstream breaks if I edit
FR-7?" meant walking the graph by hand, and cross-layer chains
(FR -> AC -> scenario -> task -> file) were invisible during review.
This module reproduces that before-state plus the missing query: the
edge list stays flat, ``find_refs`` is the one-hop oracle, and ``impact``
computes the transitive blast radius with a manual depth-labelled walk
-- an explicit stack, a visited-depth map (first arrival records the
shortest chain seen, cycles terminate), and a full linear scan of the
edge list for every popped node. ``impact_by_layer`` groups the result
the way the issue's report view asks for.
Ref: stgmt/dev-pomogator#166
"""


def layer_of(spec_id):
    """Layer of a spec id: 'FR-7' -> 'fr', 'TASK-3' -> 'task'."""
    return spec_id.split("-", 1)[0].lower()


def find_refs(edges, spec_id):
    """One-hop answer: ids that directly reference ``spec_id`` (sorted).

    This is the ``get_trace``/``find_refs`` semantics the issue starts
    from; a depth-1 ``impact`` must be its superset (the oracle test).
    """
    return sorted({src for (src, dst, _kind) in edges if dst == spec_id})


def impact(edges, spec_id, max_depth=None):
    """Transitive forward change-impact (blast radius) of ``spec_id``.

    ``edges`` is a list of ``(from, to, kind)`` triples where ``from``
    depends on ``to``. Returns ``{id: {"depth": d, "kind": k}}`` for
    every node that transitively depends on ``spec_id``: ``depth`` is
    the length of the shortest dependency chain and ``kind`` the node's
    layer. ``max_depth`` bounds the walk (include at depth, no expand).
    The stack + visited-depth map below is the hand-rolled machinery:
    one full edge-list scan per popped node.
    """
    depth = {spec_id: 0}
    stack = [spec_id]
    while stack:
        cur = stack.pop()
        d = depth[cur]
        if max_depth is not None and d >= max_depth:
            continue  # depth cap: node stays in results, not expanded
        for src, dst, _kind in edges:
            if dst != cur:
                continue
            nd = d + 1
            if src not in depth or nd < depth[src]:
                depth[src] = nd  # revisit only on a shorter chain
                stack.append(src)
    del depth[spec_id]
    return {sid: {"depth": dv, "kind": layer_of(sid)} for sid, dv in depth.items()}


def impact_by_layer(edges, spec_id, max_depth=None):
    """Impact of ``spec_id`` grouped by layer (the report's byLayer view)."""
    by = {}
    for sid, info in impact(edges, spec_id, max_depth).items():
        by.setdefault(info["kind"], []).append(sid)
    return {kind: sorted(ids) for kind, ids in by.items()}
