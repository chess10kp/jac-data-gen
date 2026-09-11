"""Tree mixin, lifted to OSP.

The parent map becomes TreeNode nodes joined by mirrored typed edges
(ChildOf upward, HasChild downward); the ancestor chain-walk and the
child-scan descent become flooding walkers. ``move_to`` is a two-phase
collect-then-rewire guarded by a descendants flood -- the check-then-
write cycle hazard the audit flagged cannot survive. Claim maps are the
explicit cycle policy: corrupt parent loops terminate because revisits
are `skip`ed (jac walkers do not dedupe).
Ref: sembeimx/nori#44
"""
node TreeNode {
    has tid: int;
}
edge ChildOf {}   # node -> parent
edge HasChild {}  # parent -> node

"""Loader handle: node ids resolve through this lookup map."""
obj Tree {
    has nodes: dict[int, TreeNode];
    has ids: list[int];

    def resolve(nid: int) -> TreeNode | None {
        return self.nodes.get(nid);
    }
}

"""Fresh-graph builder. ``nodes``: every id (roots included);
``links``: (child_id, parent_id) pairs. Creation order = fixture order."""
def build_tree(nodes: list[int], links: list[tuple[int, int]]) -> Tree {
    tree = Tree(nodes={}, ids=[]);
    for nid in nodes {
        n = TreeNode(tid=nid);
        root ++> n;
        tree.nodes[nid] = n;
        tree.ids.append(nid);
    }
    for (child_id, parent_id) in links {
        tree.nodes[child_id] +>:ChildOf:+> tree.nodes[parent_id];
        tree.nodes[parent_id] +>:HasChild:+> tree.nodes[child_id];
    }
    return tree;
}

walker AncestorClimb {
    # Cycle policy: claim-once climb; corrupt parent loops terminate.
    has claimed: dict[int, bool] = {};
    has start_id: int = 0;
    has found: list[int] = [];

    can climb with TreeNode entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        if here.tid != self.start_id {
            self.found.append(here.tid);
        }
        visit [->:ChildOf:->];
    }
}

"""All ancestors above ``node_id``, sorted; loop-guarded."""
def ancestors(tree: Tree, node_id: int) -> list[int] {
    start = tree.resolve(node_id);
    if start is None {
        return [];
    }
    w = start spawn AncestorClimb(claimed={}, start_id=node_id);
    return sorted(w.found);
}

walker DescendFlood {
    # Cycle policy: claim-once flood; revisits are skipped.
    has claimed: dict[int, bool] = {};
    has root_id: int = 0;
    has found: list[int] = [];

    can descend with TreeNode entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        if here.tid != self.root_id {
            self.found.append(here.tid);
        }
        visit [->:HasChild:->];
    }
}

"""All descendants below ``node_id`` (exclusive), sorted."""
def descendants(tree: Tree, node_id: int) -> list[int] {
    start = tree.resolve(node_id);
    if start is None {
        return [];
    }
    w = start spawn DescendFlood(claimed={}, root_id=node_id);
    return sorted(w.found);
}

"""Re-parent ``node_id`` under ``new_parent_id``.

Raises ValueError('move forms a parent cycle') when the move would make
the node a descendant of itself.
"""
def move_to(tree: Tree, node_id: int, new_parent_id: int | None) -> None {
    # phase 1: collect the subtree before any mutation
    subtree = descendants(tree, node_id);
    if new_parent_id is None {
        _detach(tree, node_id);
        return;
    }
    if new_parent_id == node_id or new_parent_id in subtree {
        raise ValueError("move forms a parent cycle");
    }
    # phase 2: rewire after the guard passed
    _detach(tree, node_id);
    n = tree.nodes[node_id];
    p = tree.nodes[new_parent_id];
    n +>:ChildOf:+> p;
    p +>:HasChild:+> n;
}

# Disconnect ``node_id`` from its current parent on both edge types.
def _detach(tree: Tree, node_id: int) -> None {
    n = tree.nodes[node_id];
    ups = [n->:ChildOf:->];
    for p in ups {
        n del ->:ChildOf:-> p;
        p del ->:HasChild:-> n;
    }
}

"""Distance from the root above ``node_id``; loop-guarded."""
def depth_of(tree: Tree, node_id: int) -> int {
    start = tree.resolve(node_id);
    if start is None {
        return 0;
    }
    w = start spawn AncestorClimb(claimed={}, start_id=node_id);
    return len(w.found);
}


test "ancestor climb and descendant flood" {
    tree = build_tree([1, 2, 3, 4, 5], [(2, 1), (3, 1), (4, 2), (5, 2)]);
    assert ancestors(tree, 4) == [1, 2];
    assert descendants(tree, 1) == [2, 3, 4, 5];
    assert depth_of(tree, 4) == 2;
    assert depth_of(tree, 1) == 0;
}

test "move_to refuses self- and descendant-targeting moves" {
    tree = build_tree([1, 2, 3, 4, 5], [(2, 1), (3, 1), (4, 2), (5, 2)]);
    raised_desc = False;
    try {
        move_to(tree, 2, 5);
    } except ValueError {
        raised_desc = True;
    }
    assert raised_desc;
    raised_self = False;
    try {
        move_to(tree, 2, 2);
    } except ValueError {
        raised_self = True;
    }
    assert raised_self;
    assert descendants(tree, 2) == [4, 5];
}

test "legal move keeps every view consistent" {
    tree = build_tree([1, 2, 3, 4, 5], [(2, 1), (3, 1), (4, 2), (5, 2)]);
    move_to(tree, 4, 3);
    assert ancestors(tree, 4) == [1, 3];
    assert descendants(tree, 2) == [5];
    move_to(tree, 5, None);
    assert ancestors(tree, 5) == [];
}

test "corrupt parent cycle terminates without truncation" {
    corrupt = build_tree([7, 8], [(7, 8), (8, 7)]);
    assert ancestors(corrupt, 7) == [8];
    assert depth_of(corrupt, 7) == 1;
    assert descendants(corrupt, 7) == [8];
}
