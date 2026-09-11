"""Dependency-tree renderer with shared-node visibility.

A verification project's modules form a "needs" graph rendered as a tree
from a root module. The original renderer closed over ONE visited set
shared across the whole traversal, so a module reachable from two branches
was attached under only the first branch -- ``veriq tree`` and its
``--invert`` impact view under-reported shared dependency paths. The fix
tracks visited state per root-to-node path (copied down each branch), so
a shared node appears under every parent while repetition along a single
path is still prevented.
Ref: ut-issl/veriq#260
"""


def load_tree(names, depends_on):
    """``depends_on``: ``(user, dependency)`` pairs -- user needs dependency."""
    dep = {n: [] for n in names}
    rdep = {n: [] for n in names}
    for user, used in depends_on:
        dep[user].append(used)
        rdep[used].append(user)
    return {"names": list(names), "dep": dep, "rdep": rdep}


def render_edges(tree, root):
    """Sorted ``parent>child`` render pairs below ``root``.

    Per-path visited policy: a child is skipped only when it already sits
    on the current root-to-node path, never because another branch got
    there first.
    """
    out = []

    def walk(name, path):
        for child in tree["dep"].get(name, []):
            if child in path:
                continue
            out.append("%s>%s" % (name, child))
            walk(child, path | {child})

    walk(root, {root})
    return sorted(out)


def dependencies_of(tree, node):
    """Transitive closure of what ``node`` needs (inclusive), sorted."""
    seen = {node}
    stack = [node]
    while stack:
        cur = stack.pop()
        for nxt in tree["dep"].get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                stack.append(nxt)
    return sorted(seen)


def dependents_of(tree, node):
    """Transitive closure of who needs ``node`` (inclusive), sorted."""
    seen = {node}
    stack = [node]
    while stack:
        cur = stack.pop()
        for nxt in tree["rdep"].get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                stack.append(nxt)
    return sorted(seen)
