"""Component-tree callback owner resolution.

A Vue table field can name a callback as a string; ``callCallback`` then
looks the method up on ``this.$parent``. When the table sits inside layout
scaffolding (``<row>``/``<column>``), the immediate parent is the layout
component and the lookup misses the page's method entirely. The fix walks
up the ``$parent`` chain until a component actually defines the function
(and caches the owner afterwards, so the ascent runs once per field).
Ref: ratiw/vuetable-2#59
"""


def load_tree(spec):
    """``spec``: {name: (parent_name_or_None, [methods])}; returns the tree."""
    comps = {}
    for name, (parent, methods) in spec.items():
        comps[name] = {"name": name, "parent": parent, "methods": set(methods)}
    return comps


def ancestors_of(tree, name):
    """Component chain in ascent order ``[name, parent, grandparent, ...]``.
    Unknown component or unknown parent ends the chain at the last known
    component."""
    chain = []
    cur = name
    while cur is not None and cur in tree:
        chain.append(cur)
        cur = tree[cur]["parent"]
    return chain


def resolve_owner(tree, name, func):
    """Name of the nearest component (self first, then ancestors) defining
    ``func``; None when no ancestor owns it."""
    for comp in ancestors_of(tree, name):
        if func in tree[comp]["methods"]:
            return comp
    return None


def has_callback(tree, name, func):
    """True when some component on the chain defines ``func``."""
    return resolve_owner(tree, name, func) is not None


def visible_methods(tree, name):
    """Sorted union of methods defined along the chain (nearest-wins lookup
    is per name; this reports everything reachable)."""
    seen = set()
    for comp in ancestors_of(tree, name):
        seen |= tree[comp]["methods"]
    return sorted(seen)
