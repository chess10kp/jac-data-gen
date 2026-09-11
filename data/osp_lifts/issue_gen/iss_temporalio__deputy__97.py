"""Composite-action inventory extraction with manifest memoization and budget.

GitHub Actions workflows can nest composite actions: a workflow step can
``uses:`` an action manifest whose own steps reference further manifests, and
a manifest can be referenced from many parents. ``parseWorkflow`` recorded
visited workflows only, while ``parseActionManifest`` re-parsed manifests
once per path, so a fan-out of depth 9 grew as ``fanout^depth`` (8.7s for
ten tiny files). The remediation extends the once-per-resource visited set
to action manifests (a manifest parsed once is never parsed again, making
growth linear in file count) and adds a global parse budget that stops the
extraction with a partial result plus a warning flag instead of running to
completion.
Ref: temporalio/deputy#97
"""

DEFAULT_BUDGET = 64


def extract(root, graph, budget=DEFAULT_BUDGET):
    """Parse the composite-action graph starting at workflow ``root``.

    ``graph`` maps unit names to the list of units their steps reference,
    split into ``graph["workflow"]`` and ``graph["manifest"]`` maps. Each
    unit is parsed at most once regardless of how many steps reference it
    (the memoization the doc comment promised). Returns
    ``{"parsed": [names], "budget_hit": bool}``; when the parse budget is
    exhausted the walk stops early with the partial parse list and
    ``budget_hit`` set.
    """
    state = {"parsed": [], "budget_hit": False}
    seen = set()
    _parse(root, graph, state, seen, budget)
    return state


def _parse(name, graph, state, seen, budget):
    if name in seen:
        return  # memoized: one parse per resource, not per path
    if len(state["parsed"]) >= budget:
        state["budget_hit"] = True
        return  # stop with a partial result rather than running on
    seen.add(name)
    state["parsed"].append(name)
    for ref in graph.get("workflow", {}).get(name, []):
        _parse(ref, graph, state, seen, budget)
    for ref in graph.get("manifest", {}).get(name, []):
        _parse(ref, graph, state, seen, budget)


def parse_count(root, graph, budget=DEFAULT_BUDGET):
    """How many units extraction parses (always 1 per unit post-fix)."""
    return len(extract(root, graph, budget)["parsed"])
