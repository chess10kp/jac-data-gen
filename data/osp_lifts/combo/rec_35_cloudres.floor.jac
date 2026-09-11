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
class Resource {
    def init(self: Resource, rid: Any, parent: Any = None, cost: Any = 0) -> object {
        self.rid = rid;
        self.parent = parent;
        self.children = [];
        self.cost = cost;
        self.agg = cost;
        self.dead = False;
    }
}
class CloudManager {
    def init(self: CloudManager) -> object {
        self.resources = {};
        self.depends = {};
    }
    def add_resource(
        self: CloudManager, rid: Any, parent: Any = None, cost: Any = 0
    ) -> object {
        if (rid in self.resources) {
            raise ValueError("duplicate resource");
        }
        if ((parent is not None) and (parent not in self.resources)) {
            raise KeyError(parent);
        }
        p = self.resources[parent] if (parent is not None) else None;
        r = Resource(rid, p, cost);
        if (p is not None) {
            p.children.append(r);
        }
        self.resources[rid] = r;
        cur: Resource | None = p as Resource | None;
        while (cur is not None) {
            cur.agg += cost;
            nxt = cur.parent as Resource | None;
            cur = nxt;
        }
        return rid;
    }
    def attach_dependency(self: CloudManager, src: Any, dst: Any) -> object {
        if (src == dst) {
            raise ValueError("self dependency");
        }
        self.depends.setdefault(src, `set()).add(dst);
    }
    """Everything rid transitively depends on (stack walk)."""
    def dependency_closure(self: CloudManager, rid: Any) -> object {
        seen = `set();
        stack = `list(self.depends.get(rid, `set()));
        while stack {
            d = stack.pop();
            if ((d in seen) or (d == rid)) {
                continue;
            }
            seen.add(d);
            stack.extend(self.depends.get(d, `set()));
        }
        return sorted(seen);
    }
    """Descendant sweep with an explicit queue."""
    def _subtree_ids(self: CloudManager, rid: Any) -> object {
        out = [];
        seen = `set();
        q = [rid];
        while q {
            cur = q.pop(0);
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            out.append(cur);
            kids = self.resources[cur].children as list;
            for c in kids {
                cr = c as Resource;
                q.append(cr.rid);
            }
        }
        return out;
    }
    """Cascade-delete rid and its subtree. Refuses while any surviving
        resource still depends on a member of the doomed set. Recomputes
        ancestor aggregates afterwards."""
    def delete(self: CloudManager, rid: Any) -> object {
        if (rid not in self.resources) {
            raise KeyError(rid);
        }
        doomed = `set(self._subtree_ids(rid));
        for (src, ds) in self.depends.items() {
            if (src in doomed) {
                continue;
            }
            if (ds & doomed) {
                raise ValueError("resource in use");
            }
        }
        parent = self.resources[rid].parent;
        removed_cost = sum(self.resources[d].cost for d in doomed);
        for d in doomed {
            r = self.resources.pop(d);
            r.dead = True;
        }
        if (parent is not None) {
            kept = [];
            pr = parent as Resource;
            pc = pr.children as list;
            for c in pc {
                cr = c as Resource;
                if (cr.rid != rid) {
                    kept.append(cr);
                }
            }
            pr.children = kept;
        }
        cur2: Resource | None = parent as Resource | None;
        while (cur2 is not None) {
            cur2.agg -= removed_cost;
            cur = cur.parent;
        }
        for src in `list(self.depends) {
            if (src in doomed) {
                delete(self.depends[src],);
                continue;
            }
            self.depends[src] = self.depends[src] - doomed;
        }
        return sorted(doomed);
    }

    def aggregate(self: CloudManager, rid: Any) -> object {
        return self.resources[rid].agg;
    }
    def ancestors(self: CloudManager, rid: Any) -> object {
        chain = [];
        cur3: Resource | None = self.resources[rid].parent as Resource | None;
        while (cur3 is not None) {
            chain.append(cur3.rid);
            cur3 = cur3.parent as Resource | None;
        }
        return chain;
    }
}

