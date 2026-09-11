"""Game tech tree.

Research branches form a hierarchy (branches contain sub-branches and
technologies). Technologies have prerequisites forming a DAG across
branches. Planning a research path requires walking prerequisite chains.

Hand-rolled machinery:
- parent/children pointers over the branch tree (C1)
- prerequisite adjacency dict with stack walks and a visited set (C2)
"""
class Branch {
    def init(self: Branch, bid: Any, parent: Any = None) -> object {
        self.bid = bid;
        self.parent = parent;
        self.children = [];
        self.techs = [];
    }
}
class TechTree {
    def init(self: TechTree) -> object {
        self.branches = {};
        self.techs = {};
        self.prereqs = {};
    }
    def add_branch(self: TechTree, bid: Any, parent: Any = None) -> object {
        if (bid in self.branches) {
            raise ValueError("duplicate branch");
        }
        p = self.branches[parent] if (parent is not None) else None;
        b = Branch(bid, p);
        if (p is not None) {
            p.children.append(b);
        }
        self.branches[bid] = b;
        return bid;
    }
    def add_tech(self: TechTree, tid: Any, bid: Any, era: Any) -> object {
        if (tid in self.techs) {
            raise ValueError("duplicate tech");
        }
        if (bid not in self.branches) {
            raise KeyError(bid);
        }
        self.techs[tid] = (bid, era);
        self.branches[bid].techs.append(tid);
    }
    def require(self: TechTree, tid: Any, prereq_tid: Any) -> object {
        self.prereqs.setdefault(tid, []).append(prereq_tid);
    }
    """All technologies under the branch subtree (recursive descent)."""
    def subtree_techs(self: TechTree, bid: Any) -> object {
        out = [];
        b = self.branches[bid];
        def descend(br: Branch) -> object {
            out.extend(br.techs);
            for c in br.children {
                descend(c);
            }
        }
        descend(b);
        return sorted(out);
    }
    """Transitive prerequisites of tid not in researched. Cycle safe."""
    def remaining_prereqs(self: TechTree, researched: Any, tid: Any) -> object {
        todo = `set();
        seen = `set();
        stack = [p for p in self.prereqs.get(tid, [])];
        while stack {
            t = stack.pop();
            if ((t in seen) or (t == tid)) {
                continue;
            }
            seen.add(t);
            if (t not in researched) {
                todo.add(t);
            }
            stack.extend(self.prereqs.get(t, []));
        }
        return sorted(todo);
    }
    def can_research(self: TechTree, researched: Any, tid: Any) -> object {
        return all((p in researched) for p in self.prereqs.get(tid, []));
    }
    def era_of(self: TechTree, tid: Any) -> object {
        return self.techs[tid][1];
    }
}

