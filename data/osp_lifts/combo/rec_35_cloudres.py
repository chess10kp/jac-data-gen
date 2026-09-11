"""Cloud resource dependency manager.

Resources form a deployment tree (stacks contain nested resources). Cross-
stack dependency links exist between resources. Deleting a resource cascades
to its whole subtree but must respect dependencies from surviving resources,
and every ancestor's aggregated cost must be recomputed.

Hand-rolled machinery:
- parent/children pointers plus incremental ancestor aggregation (C1)
- dependency adjacency dict with a queue-based descendant sweep (C5, and a
  stack-based closure walk for dependency queries)
"""


class Resource:
    def __init__(self, rid, parent=None, cost=0):
        self.rid = rid
        self.parent = parent
        self.children = []
        self.cost = cost          # own cost
        self.agg = cost           # subtree cost, maintained incrementally
        self.dead = False


class CloudManager:
    def __init__(self):
        self.resources = {}  # rid -> Resource
        self.depends = {}    # rid -> set of rids it depends on

    def add_resource(self, rid, parent=None, cost=0):
        if rid in self.resources:
            raise ValueError("duplicate resource " + rid)
        if parent is not None and parent not in self.resources:
            raise KeyError(parent)
        p = self.resources[parent] if parent is not None else None
        r = Resource(rid, p, cost)
        if p is not None:
            p.children.append(r)
        self.resources[rid] = r
        cur = p
        while cur is not None:      # ancestor-aware aggregation
            cur.agg += cost
            cur = cur.parent
        return rid

    def attach_dependency(self, src, dst):
        if src == dst:
            raise ValueError("self dependency")
        self.depends.setdefault(src, set()).add(dst)

    def dependency_closure(self, rid):
        """Everything rid transitively depends on (stack walk)."""
        seen = set()
        stack = list(self.depends.get(rid, set()))
        while stack:
            d = stack.pop()
            if d in seen or d == rid:
                continue
            seen.add(d)
            stack.extend(self.depends.get(d, set()))
        return sorted(seen)

    def _subtree_ids(self, rid):
        """Descendant sweep with an explicit queue."""
        out = []
        seen = set()
        q = [rid]
        while q:
            cur = q.pop(0)
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            q.extend(c.rid for c in self.resources[cur].children)
        return out

    def delete(self, rid):
        """Cascade-delete rid and its subtree. Refuses while any surviving
        resource still depends on a member of the doomed set. Recomputes
        ancestor aggregates afterwards."""
        if rid not in self.resources:
            raise KeyError(rid)
        doomed = set(self._subtree_ids(rid))
        for src, ds in self.depends.items():
            if src in doomed:
                continue
            if ds & doomed:
                raise ValueError("resource in use: " + rid)
        parent = self.resources[rid].parent
        removed_cost = sum(self.resources[d].cost for d in doomed)
        for d in doomed:
            r = self.resources.pop(d)
            r.dead = True
        if parent is not None:
            parent.children = [c for c in parent.children
                               if c.rid != rid]
        cur = parent
        while cur is not None:      # ancestor-aware recomputation
            cur.agg -= removed_cost
            cur = cur.parent
        for src in list(self.depends):
            if src in doomed:
                del self.depends[src]
                continue
            self.depends[src] -= doomed
        return sorted(doomed)

    def aggregate(self, rid):
        return self.resources[rid].agg

    def ancestors(self, rid):
        chain = []
        cur = self.resources[rid].parent
        while cur is not None:
            chain.append(cur.rid)
            cur = cur.parent
        return chain
