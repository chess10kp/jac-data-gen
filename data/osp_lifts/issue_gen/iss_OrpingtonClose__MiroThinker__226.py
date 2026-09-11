"""Recursive SYNTHESIZE lineage over the findings parent DAG.

The Flock's ConditionStore keeps every finding in a flat cluster bucket:
``findings`` is a list of records ``{"id", "cluster", "weight",
"parent_ids"}``, and a synthesis produced in round 1 links back to its
source findings through ``parent_ids``. SYNTHESIZE only ever queried flat
cluster membership, so that lineage DAG was never traversed and round 2
could not discover shared ancestry. The remediation adds the recursive
lineage walk the issue asks for: ancestors within a bounded number of
hops (depth limit 10 to prevent runaway), ``synthesis_depth`` metadata
counting how many synthesis layers deep a finding sits (its longest root
chain), and a priority boost for higher-depth syntheses.
Ref: OrpingtonClose/MiroThinker#226
"""

MAX_LINEAGE_DEPTH = 10
DEPTH_BOOST = 5
DEPTH_BOOST_THRESHOLD = 2


def lineage(findings, fid, max_depth=MAX_LINEAGE_DEPTH):
    """Ancestor ids of ``fid`` within ``max_depth`` parent hops, sorted.

    Recursive walk up the ``parent_ids`` DAG tracking the shortest hop
    count at which each ancestor is reached (a later, shallower arrival
    re-walks from the better depth), so an ancestor counts exactly when
    some parent chain of length <= ``max_depth`` reaches it. Unknown ids
    inside ``parent_ids`` are skipped; an unknown ``fid`` raises KeyError.
    """
    by_id = {f["id"]: f for f in findings}
    if fid not in by_id:
        raise KeyError(fid)
    depths = {}

    def walk(cur, d: int):
        if cur in depths and depths[cur] <= d:
            return  # already reached at least as shallow: nothing to add
        depths[cur] = d
        if d >= max_depth:
            return  # depth limit prevents runaway, as the CTE's WHERE does
        for p in by_id[cur]["parent_ids"]:
            if p in by_id:
                walk(p, d + 1)

    walk(fid, 0)
    return sorted(x for x in depths if x != fid)


def synthesis_depth(findings, fid):
    """How many synthesis layers deep ``fid`` sits: longest root chain."""
    by_id = {f["id"]: f for f in findings}
    if fid not in by_id:
        raise KeyError(fid)
    cache = {}

    def depth_of(cur):
        if cur in cache:
            return cache[cur]
        parents = [p for p in by_id[cur]["parent_ids"] if p in by_id]
        best = -1
        for p in parents:
            dp = int(depth_of(p))
            if dp > best:
                best = dp
        cache[cur] = best + 1
        return best + 1

    return depth_of(fid)


def priority(findings, fid):
    """Base weight of ``fid``, boosted once synthesis depth >= 2."""
    by_id = {f["id"]: f for f in findings}
    if fid not in by_id:
        raise KeyError(fid)
    base = by_id[fid]["weight"]
    if synthesis_depth(findings, fid) >= DEPTH_BOOST_THRESHOLD:
        base += DEPTH_BOOST
    return base
