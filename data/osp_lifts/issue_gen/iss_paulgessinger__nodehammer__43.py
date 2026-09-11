"""Scene graph: world transforms and reachability over a parent hierarchy.

paulgessinger/nodehammer#43: scene traversals hang or silently corrupt on
cyclic graphs. computeWorldTransforms walks the node tree multiplying local
transforms into world transforms, and reachableNodes collects descendants;
the in-memory core below keeps the id-keyed node table, the per-visit
whole-table child rescan, and the queue walk. The hardened contract raises
a controlled CycleError when a parent loop exists instead of hanging.
"""


class CycleError(ValueError):
    """The node hierarchy contains a parent cycle."""


class SceneGraph:
    def __init__(self):
        self.parent = {}  # nid -> parent nid or None
        self.local = {}   # nid -> float local transform

    def add_node(self, nid, parent=None, local=1.0):
        if parent is not None and parent not in self.parent:
            raise KeyError(parent)
        self.parent[nid] = parent
        self.local[nid] = float(local)

    def children(self, nid):
        return sorted(c for c, p in self.parent.items() if p == nid)

    def ancestors(self, nid):
        chain = []
        seen = set()
        cur = self.parent.get(nid)
        while cur is not None:
            if cur in seen:
                raise CycleError("parent cycle")
            seen.add(cur)
            chain.append(cur)
            cur = self.parent.get(cur)
        return chain

    def world_transform(self, nid):
        """Product of local transforms along root -> nid (inclusive)."""
        prod = 1.0
        for anc in reversed(self.ancestors(nid)):
            prod *= self.local[anc]
        return round(prod * self.local[nid], 6)

    def compute_world_transforms(self):
        return {n: self.world_transform(n) for n in self.parent}

    def reachable(self, start):
        """Descendants of start including itself (guarded queue walk)."""
        seen = set()
        queue = [start]
        while queue:
            cur = queue.pop(0)  # O(N) list dequeue, per issue's inventory
            if cur in seen:
                continue
            seen.add(cur)
            queue.extend(self.children(cur))  # whole-table rescan/visit
        return sorted(seen)

    def validate_acyclic(self):
        for n in self.parent:
            self.ancestors(n)
        return True
