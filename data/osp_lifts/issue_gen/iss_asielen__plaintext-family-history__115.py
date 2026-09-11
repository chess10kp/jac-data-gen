"""Genealogy archive traversal: pedigree ancestry and the descendant fan.

Persons link through typed relations (``parent``, ``spouse``). The home
view walks ``parent`` edges up to an apex ancestor and fans forward
across everyone descended from them; a marriage-aware view must also
attach spouses of the fan. The hand-rolled engine recurses over
id-keyed relation maps with per-call visited sets, and -- the gap this
issue files -- never fetches ``spouse`` relations at all, so married-in
partners vanish from every traversal.
Ref: asielen/plaintext-family-history#115
"""


def load_family(persons, relations):
    """``persons``: ids. ``relations``: (kind, a, b) with kind in
    {'parent', 'spouse'}; ('parent', child, parent) links child->parent."""
    parents = {p: [] for p in persons}
    children = {p: [] for p in persons}
    spouses = {p: [] for p in persons}
    for kind, a, b in relations:
        if kind == "parent":
            parents[a].append(b)
            children[b].append(a)
        elif kind == "spouse":
            spouses[a].append(b)
            spouses[b].append(a)
    return {"parents": parents, "children": children, "spouses": spouses}


def ancestors_within(fam, person, generations):
    """Ancestors of ``person`` within ``generations`` hops (exclusive),
    sorted. Shared ancestors appear once."""
    seen = set()
    frontier = [person]
    for _ in range(generations):
        nxt = []
        for cur in frontier:
            for par in fam["parents"].get(cur, []):
                if par not in seen:
                    seen.add(par)
                    nxt.append(par)
        frontier = nxt
        if not frontier:
            break
    return sorted(seen)


def descendant_fan(fam, person):
    """Everyone descending from ``person`` (inclusive), sorted once."""
    seen = {person}
    stack = [person]
    while stack:
        cur = stack.pop()
        for kid in fam["children"].get(cur, []):
            if kid not in seen:
                seen.add(kid)
                stack.append(kid)
    return sorted(seen)


def in_laws(fam, person):
    """Spouses of anyone in ``person``'s descendant fan who are not
    themselves blood descendants -- the married-in partners the shipped
    engine dropped. Sorted, exclusive of ``person``'s own spouse? No:
    every such spouse is included, blood or not is decided by the fan."""
    fan = descendant_fan(fam, person)
    fan_set = set(fan)
    married_in = set()
    for member in fan:
        for sp in fam["spouses"].get(member, []):
            if sp not in fan_set:
                married_in.add(sp)
    return sorted(married_in)


def apex_ancestor_depth(fam, person):
    """Length of the longest parent chain above ``person``.

    Computed level-by-level so shared ancestors converge regardless of
    path order."""
    depth = 0
    seen = {person}
    frontier = [person]
    while frontier:
        nxt = []
        for cur in frontier:
            for par in fam["parents"].get(cur, []):
                if par not in seen:
                    seen.add(par)
                    nxt.append(par)
        if not nxt:
            break
        depth += 1
        frontier = nxt
    return depth
