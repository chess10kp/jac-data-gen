"""Game tech tree.

Research branches form a hierarchy (branches contain sub-branches and
technologies). Technologies have prerequisites forming a DAG across
branches. Planning a research path requires walking prerequisite chains.

Hand-rolled machinery:
- parent/children pointers over the branch tree (C1)
- prerequisite adjacency dict with stack walks and a visited set (C2)
"""


class Branch:
    def __init__(self, bid, parent=None):
        self.bid = bid
        self.parent = parent
        self.children = []
        self.techs = []


class TechTree:
    def __init__(self):
        self.branches = {}  # bid -> Branch
        self.techs = {}     # tid -> bid
        self.prereqs = {}   # tid -> list of prerequisite tids

    def add_branch(self, bid, parent=None):
        if bid in self.branches:
            raise ValueError("duplicate branch " + bid)
        p = self.branches[parent] if parent is not None else None
        b = Branch(bid, p)
        if p is not None:
            p.children.append(b)
        self.branches[bid] = b
        return bid

    def add_tech(self, tid, bid, era):
        if tid in self.techs:
            raise ValueError("duplicate tech " + tid)
        if bid not in self.branches:
            raise KeyError(bid)
        self.techs[tid] = (bid, era)
        self.branches[bid].techs.append(tid)

    def require(self, tid, prereq_tid):
        self.prereqs.setdefault(tid, []).append(prereq_tid)

    def subtree_techs(self, bid):
        """All technologies under the branch subtree (recursive descent)."""
        out = []
        b = self.branches[bid]

        def descend(node):
            out.extend(node.techs)
            for c in node.children:
                descend(c)

        descend(b)
        return sorted(out)

    def remaining_prereqs(self, researched, tid):
        """Transitive prerequisites of tid not in researched. Cycle safe."""
        todo = set()
        seen = set()
        stack = [p for p in self.prereqs.get(tid, [])]
        while stack:
            t = stack.pop()
            if t in seen or t == tid:
                continue
            seen.add(t)
            if t not in researched:
                todo.add(t)
            stack.extend(self.prereqs.get(t, []))
        return sorted(todo)

    def can_research(self, researched, tid):
        return all(p in researched for p in self.prereqs.get(tid, []))

    def era_of(self, tid):
        return self.techs[tid][1]
