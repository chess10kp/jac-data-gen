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
"""``depends_on``: ``(user, dependency)`` pairs -- user needs dependency."""
def load_tree(names: Any, depends_on: Any) -> object {
    dep = {n: [] for n in names};
    rdep = {n: [] for n in names};
    for (user, used) in depends_on {
        dep[user].append(used);
        rdep[used].append(user);
    }
    return {"names": `list(names), "dep": dep, "rdep": rdep};
}
"""Sorted ``parent>child`` render pairs below ``root``.

    Per-path visited policy: a child is skipped only when it already sits
    on the current root-to-node path, never because another branch got
    there first.
    """
def render_edges(tree: Any, `root: Any) -> object {
    out = [];
    def walk(name: Any, path: Any) -> object {
        for child in tree["dep"].get(name, []) {
            if (child in path) {
                continue;
            }
            out.append(("%s>%s" % (name, child)));
            walk(child, (path | {child}));
        }
    }
    walk(`root, {`root});
    return sorted(out);
}

"""Transitive closure of what ``node`` needs (inclusive), sorted."""
def dependencies_of(tree: Any, `node: Any) -> object {
    seen = {`node};
    stack = [`node];
    while stack {
        cur = stack.pop();
        for nxt in tree["dep"].get(cur, []) {
            if (nxt not in seen) {
                seen.add(nxt);
                stack.append(nxt);
            }
        }
    }
    return sorted(seen);
}
"""Transitive closure of who needs ``node`` (inclusive), sorted."""
def dependents_of(tree: Any, `node: Any) -> object {
    seen = {`node};
    stack = [`node];
    while stack {
        cur = stack.pop();
        for nxt in tree["rdep"].get(cur, []) {
            if (nxt not in seen) {
                seen.add(nxt);
                stack.append(nxt);
            }
        }
    }
    return sorted(seen);
}

