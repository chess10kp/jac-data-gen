"""Build-system dependency auditor.

Modules declare what they depend on; the workspace keeps an adjacency dict
of module -> list of dependency module names. Audits walk dependencies with
an explicit list-as-stack depth-first search.
"""


def build_workspace(modules, depends):
    """Adjacency dict; depends are (module, dependency, kind) triples."""
    ws = {m: [] for m in modules}
    for m, d, _kind in depends:
        ws[m].append(d)
    return ws


def closure(ws, mod):
    """Transitive dependencies of ``mod`` (sorted, excluding itself)."""
    if mod not in ws:
        return []
    seen = set()
    stack = list(ws[mod])
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        stack.extend(ws[cur])
    seen.discard(mod)   # exclude the root even under dependency cycles
    return sorted(seen)


def depends_on_chain(ws, src, dst):
    """True when ``dst`` sits at least one dependency edge below ``src``.

    ``depends_on_chain(ws, m, m)`` is therefore true only when ``m`` is a
    (transitive) dependency of itself.
    """
    if src not in ws or dst not in ws:
        return False
    seen = set()
    stack = list(ws[src])
    while stack:
        cur = stack.pop()
        if cur == dst:
            return True
        if cur in seen:
            continue
        seen.add(cur)
        stack.extend(ws[cur])
    return False
