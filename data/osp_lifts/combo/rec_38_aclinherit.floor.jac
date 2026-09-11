"""Access-control system with role inheritance and revocation cascades.

Roles inherit from parent roles forming a hierarchy; permissions are granted
to roles as cross-links; each role caches its effective permission set.
Revoking a permission must strip it from every holder and every inherited-
role below them, invalidate the affected caches, and keep a deterministic
grant chain (nearest role first) for precedence queries.

Hand-rolled machinery:
- parent/children pointers over the role hierarchy (C1)
- permission->roles adjacency dict plus BFS descent for invalidation (C2/C5)
- incremental cache maintenance validated against recomputation
"""
class Role {
    def init(self: Role, rid: Any, parent: Any = None) -> object {
        self.rid = rid;
        self.parent = parent;
        self.children = [];
        self.cache = `set();
    }
}
class AclSystem {
    def init(self: AclSystem) -> object {
        self.roles = {};
        self.grants = {};
    }
    def add_role(self: AclSystem, rid: Any, parent: Any = None) -> object {
        if (rid in self.roles) {
            raise ValueError("duplicate role");
        }
        p = self.roles[parent] if (parent is not None) else None;
        r = Role(rid, p);
        if (p is not None) {
            p.children.append(r);
        }
        self.roles[rid] = r;
        return rid;
    }
    def grant(self: AclSystem, rid: Any, perm: Any) -> object {
        self.roles[rid].cache.add(perm);
        for anc in self._descendant_ids(rid) {
            self.roles[anc].cache.add(perm);
        }
        self.grants.setdefault(perm, `set()).add(rid);
    }
    """Queue sweep over the role subtree."""
    def _descendant_ids(self: AclSystem, rid: Any) -> list {
        out = [];
        q = [rid];
        while q {
            cur = q.pop(0);
            out.append(cur);
            kids = (self.roles[cur] as Role).children as list;
            for c in kids {
                cr = c as Role;
                q.append(cr.rid);
            }
        }
        return out;
    }
    """Grant evaluation order: the role itself first, then ancestors."""
    def chain(self: AclSystem, rid: Any) -> object {
        chain = [];
        cur = self.roles[rid];
        while (cur is not None) {
            chain.append(cur.rid);
            cur = cur.parent;
        }
        return chain;
    }
    """Permissions granted directly to rid."""
    def direct_grants(self: AclSystem, rid: Any) -> object {
        return sorted(
            p
            for (p, holders) in self.grants.items()
            if (rid in holders)
        );
    }
    def effective(self: AclSystem, rid: Any) -> object {
        eff = self.roles[rid].cache as set;
        return sorted(eff);
    }
    def _recompute(self: AclSystem, rid: Any) -> set {
        out = set();
        cur2: Role | None = self.roles[rid] as Role | None;
        while (cur2 is not None) {
            for perm_name in self.grants.keys() {
                holder_set = self.grants[perm_name] as set;
                c3 = cur2 as Role;
                if (c3.rid in holder_set) {
                    out.add(perm_name);
                }
            }
            nxt = cur2.parent as Role | None;
            cur2 = nxt;
        }
        return out;
    }
    """Strip perm from all holders and their sub-trees; invalidate
        caches accordingly. Returns sorted list of affected roles."""
    def revoke(self: AclSystem, perm: Any) -> object {
        holders = sorted(self.grants.get(perm, set()) as list);
        if not holders {
            return [];
        }
        delete(self.grants[perm],);
        affected = `set();
        for h in holders {
            for rid in self._descendant_ids(h) {
                role = self.roles[rid];
                role.cache.discard(perm);
                affected.add(rid);
            }
        }
        return sorted(affected);
    }

    """Invariant: every cached set equals the recomputed truth."""
    def cache_coherent(self: AclSystem) -> bool {
        for (rid, role) in self.roles.items() {
            if (role.cache != self._recompute(rid)) {
                return False;
            }
        }
        return True;
    }
}

