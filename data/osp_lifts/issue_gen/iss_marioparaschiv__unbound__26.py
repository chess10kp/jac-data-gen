"""Module import-graph audits: circular dependencies and layer direction.

The import graph is held as adjacency lists and walked with depth-first
searches: a module lies on a cycle exactly when a walk started at it can
reach back to it, so the audit probes self-reachability for every module
using an explicit work stack and a visited set. On top of the cycle audit,
the layering rule (api -> managers -> stores -> builtins) flags every
import edge that points upward in the layer order as a violation; an
import may go downward or stay within its layer.
Ref: marioparaschiv/unbound#26
"""

LAYER_ORDER = {"api": 0, "managers": 1, "stores": 2, "builtins": 3}


def has_cycle(graph):
    """True iff any module participates in an import cycle."""
    return len(nodes_in_cycles(graph)) > 0


def nodes_in_cycles(graph):
    """Sorted list of every module that can reach itself via imports.

    ``graph`` is ``{"imports": {module: [imported, ...]}, "layers":
    {module: layer}}``; a module without a declared layer is treated as
    "builtins". Result order is normalized because probe order is an
    internal artifact of the audit.
    """
    imports = graph.get("imports", {})
    out = []
    for mod in _all_modules(imports):
        if _reaches(imports, mod, mod):
            out.append(mod)
    return sorted(out)


def layer_violations(graph):
    """Sorted ``"src->dst"`` strings for imports that point up the layers."""
    imports = graph.get("imports", {})
    layers = graph.get("layers", {})
    out = []
    for src, deps in imports.items():
        for dst in deps:
            s_lvl = LAYER_ORDER[layers.get(src, "builtins")]
            d_lvl = LAYER_ORDER[layers.get(dst, "builtins")]
            if d_lvl < s_lvl:
                out.append(f"{src}->{dst}")
    return sorted(out)


def _all_modules(imports):
    mods = set(imports.keys())
    for deps in imports.values():
        mods.update(deps)
    return sorted(mods)


def _reaches(imports, src, dst):
    # Iterative DFS from src's imports: explicit stack + visited set.
    seen = set()
    stack = list(imports.get(src, []))
    while stack:
        mod = stack.pop()
        if mod == dst:
            return True
        if mod in seen:
            continue
        seen.add(mod)
        stack.extend(imports.get(mod, []))
    return False
