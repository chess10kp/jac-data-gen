"""dbt-style model selection with dependency resolution.

francescomucio/tee-for-transform#8: the importer's --select/--exclude options
gain dbt semantics -- ``model+`` pulls the model plus all upstream
dependencies, ``+model`` pulls it plus all downstream dependents, and ``+1``
variants bound the traversal depth. The dependency graph is an in-memory
adjacency dict walked by bounded breadth-first loops; circular dependencies
must terminate gracefully. Selection results are sets of model names.
"""


def build_model_graph(models, refs):
    """Adjacency dicts; refs are (model, depends_on) pairs of declared names."""
    deps = {m: [] for m in models}       # model -> its dependencies (upstream)
    dependents = {m: [] for m in models}
    for model, dep in refs:
        if model in deps and dep in deps:
            if dep not in deps[model]:
                deps[model].append(dep)
                dependents[dep].append(model)
    return deps, dependents


def _bounded_closure(links, start, depth):
    """links is an adjacency dict; depth counts hops from ``start``."""
    seen = set()
    frontier = [start]
    level = 0
    while frontier and level < depth:
        nxt = []
        for cur in frontier:
            for nb in links.get(cur, []):
                if nb not in seen:
                    seen.add(nb)
                    nxt.append(nb)
        frontier = nxt
        level += 1
    return seen


def parse_select(spec):
    """Split a dbt-style spec into (model_name, direction, depth).

    direction is "upstream" for ``model+`` and "downstream" for ``+model``;
    each trailing ``+`` (or ``+N``) counts one hop (or N hops) of depth;
    a plain name has depth 0. Combining leading and trailing pluses is
    ambiguous and rejected.
    """
    import re

    body = spec.strip()
    lead = 0
    while body.startswith("+"):
        lead += 1
        body = body[1:]
    trail = 0
    while True:
        m = re.search(r"\+(\d*)$", body)
        if not m:
            break
        trail += int(m.group(1)) if m.group(1) else 1
        body = body[:m.start()]
    if lead and trail:
        raise ValueError("ambiguous spec: " + spec)
    if trail:
        return (body.strip(), "upstream", trail)
    if lead:
        return (body.strip(), "downstream", lead)
    return (body.strip(), "exact", 0)


def select_models(deps, dependents, spec):
    """Models matched by one dbt-style selection spec (sorted, incl. anchor)."""
    name, direction, hops = parse_select(spec)
    if name not in deps:
        return []
    if direction == "upstream":
        reach = _bounded_closure(deps, name, hops)
    elif direction == "downstream":
        reach = _bounded_closure(dependents, name, hops)
    else:
        reach = set()
    return sorted(reach | {name})


def resolve_selection(deps, dependents, specs):
    """Union over several selection specs (sorted); excludes nothing here."""
    chosen = set()
    for spec in specs:
        chosen.update(select_models(deps, dependents, spec))
    return sorted(chosen)
