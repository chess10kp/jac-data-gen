"""Tree mixin: cycle-safe moves and guarded ancestor walks.

A generic tree mixin keeps a ``parent_id`` on every node (roots have
none). ``move_to()`` must refuse any move that would make the node a
descendant of itself -- the audit flagged the check-then-write window;
``ancestors()`` / ``descendants()`` walk parent and child chains with a
``seen`` set as defense in depth, because once a corrupt parent cycle
exists every naive recursive walk over it hangs.
Ref: sembeimx/nori#44
"""
"""Raised when move_to would form a parent cycle."""
class CycleMove(ValueError) {}
"""``nodes``: every node id (roots included). ``links``:
    ``(child_id, parent_id)`` pairs."""
def build_tree(nodes: Any, links: Any) -> object {
    tree = {"nodes": `list(nodes), "parent": {n: None for n in nodes}};
    for (child, parent) in links {
        tree["parent"][child] = parent;
    }
    return tree;
}

"""All ancestors above ``node_id``, sorted; loop-guarded."""
def ancestors(tree: Any, node_id: Any) -> object {
    seen = {node_id};
    cur = tree["parent"].get(node_id);
    while ((cur is not None) and (cur not in seen)) {
        seen.add(cur);
        cur = tree["parent"].get(cur);
    }
    return sorted((seen - {node_id}));
}
"""All descendants below ``node_id`` (exclusive), sorted."""
def descendants(tree: Any, node_id: Any) -> object {
    seen = `set();
    stack = [
        c
        for (c, p) in tree["parent"].items()
        if (p == node_id)
    ];
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        stack.extend(
            c
            for (c, p) in tree["parent"].items()
            if (p == cur)
        );
    }
    return sorted((seen - {node_id}));
}
"""Re-parent ``node_id`` under ``new_parent_id``.

    Raises CycleMove when ``new_parent_id`` is the node itself or one of
    its descendants.
    """
def move_to(tree: Any, node_id: Any, new_parent_id: Any) -> object {
    if (new_parent_id is None) {
        tree["parent"][node_id] = None;
        return;
    }
    if ((new_parent_id == node_id) or (new_parent_id in descendants(tree, node_id))) {
        raise CycleMove("move forms a parent cycle");
    }
    tree["parent"][node_id] = new_parent_id;
}

"""Distance from the root above ``node_id``; loop-guarded."""
def depth_of(tree: Any, node_id: Any) -> object {
    depth = 0;
    seen = {node_id};
    cur = tree["parent"].get(node_id);
    while ((cur is not None) and (cur not in seen)) {
        depth += 1;
        seen.add(cur);
        cur = tree["parent"].get(cur);
    }
    return depth;
}

