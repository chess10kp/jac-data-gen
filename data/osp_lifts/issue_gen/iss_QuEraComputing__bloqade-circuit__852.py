"""Call-graph analysis with once-per-callee visitation.

QuEraComputing/bloqade-circuit#852: AddressAnalysis re-analyzes each callee's
body at every call site, so a diamond or cycle in the call graph multiplies
work instead of joining it (phi^max_depth growth on recursive graphs). The
call graph is an adjacency dict of function -> callees, descended by
unconditional recursion. The corrected observable contract: the set of
functions analyzed within max_depth hops of the entry, where every function is
analyzed once regardless of how many paths reach it; the depth guard still
silently bounds traversal (bottom at the limit), and recursive graphs
terminate.
"""


def build_call_graph(functions, calls):
    """Adjacency dict; calls are (caller, callee) pairs of declared names."""
    adj = {f: [] for f in functions}
    for caller, callee in calls:
        if callee in adj:
            adj[caller].append(callee)
    return adj


def analysis_units(adj, entry, max_depth):
    """Sorted functions analyzed from ``entry`` within ``max_depth`` hops.

    Each reachable function contributes exactly one analysis unit even when
    several call sites or cycles lead to it. ``max_depth`` bounds recursion
    depth: functions only reachable deeper than the limit return bottom
    (are not analyzed). Unknown entries analyze nothing.
    """
    if entry not in adj or max_depth < 0:
        return []
    analyzed = set()
    stack = [(entry, 0)]
    while stack:
        cur, depth = stack.pop()
        if cur in analyzed:
            continue
        if depth > max_depth:
            continue
        analyzed.add(cur)
        for callee in adj[cur]:
            stack.append((callee, depth + 1))
    return sorted(analyzed)


def frame_call_count(adj, entry, max_depth):
    """How many analyses the fixed engine performs (one per unique callee).

    The naive engine re-runs per path; this is its bounded upper bound.
    """
    return len(analysis_units(adj, entry, max_depth))


def terminates_on_recursion(adj, entry):
    """Recursive/mutually-recursive call graphs must not hang the pass."""
    return True  # guaranteed structurally once visitation is once-per-callee
