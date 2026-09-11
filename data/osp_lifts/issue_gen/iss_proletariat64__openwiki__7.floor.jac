"""proletariat64/openwiki#7 — Reduce batch checkpoint parent-child tree.

Reduce nodes form a parent-child lineage; committed checkpoints unlock
pending leaf batches via ancestor chain inspection.
"""
import from __future__ { annotations }
class ReduceTree {
    def init(self: ReduceTree) -> None {
        self.parent_of: dict[(str, (str | None))] = {};
        self.children_of: dict[(str, list[str])] = {};
    }
}
def load_reduce_tree(
    nodes: list[str], parent_edges: list[tuple[(str, str)]]
) -> ReduceTree {
    tree = ReduceTree();
    for nid in nodes {
        tree.parent_of.setdefault(nid, None);
        tree.children_of.setdefault(nid, []);
    }
    for (parent, child) in parent_edges {
        if ((parent in tree.parent_of) and (child in tree.parent_of)) {
            tree.parent_of[child] = parent;
            tree.children_of.setdefault(parent, []).append(child);
        }
    }
    return tree;
}
def lineage(tree: ReduceTree, node_id: str) -> list[str] {
    if (node_id not in tree.parent_of) {
        return [];
    }
    chain: list[str] = [];
    cur: (str | None) = node_id;
    seen: set[str] = `set();
    while (cur is not None) {
        if (cur in seen) {
            break;
        }
        seen.add(cur);
        chain.append(cur);
        cur = tree.parent_of.get(cur);
    }
    chain.reverse();
    return chain;
}
def pending_leaves(tree: ReduceTree, committed: list[str]) -> list[str] {
    done = `set(committed);
    leaves: list[str] = [];
    for nid in sorted(tree.parent_of) {
        if tree.children_of.get(nid, []) {
            continue;
        }
        ancestors = [
            a
            for a in lineage(tree, nid)
            if (a != nid)
        ];
        if all((a in done) for a in ancestors) {
            if (nid not in done) {
                leaves.append(nid);
            }
        }
    }
    return sorted(leaves);
}

