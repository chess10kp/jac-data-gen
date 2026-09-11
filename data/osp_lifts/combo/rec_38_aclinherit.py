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


class Role:
    def __init__(self, rid, parent=None):
        self.rid = rid
        self.parent = parent
        self.children = []
        self.cache = set()   # cached effective permissions


class AclSystem:
    def __init__(self):
        self.roles = {}     # rid -> Role
        self.grants = {}    # perm -> set of rids holding it directly

    def add_role(self, rid, parent=None):
        if rid in self.roles:
            raise ValueError("duplicate role " + rid)
        p = self.roles[parent] if parent is not None else None
        r = Role(rid, p)
        if p is not None:
            p.children.append(r)
        self.roles[rid] = r
        return rid

    def grant(self, rid, perm):
        self.roles[rid].cache.add(perm)
        for anc in self._descendant_ids(rid):
            self.roles[anc].cache.add(perm)
        self.grants.setdefault(perm, set()).add(rid)

    def _descendant_ids(self, rid):
        """Queue sweep over the role subtree."""
        out = []
        q = [rid]
        while q:
            cur = q.pop(0)
            out.append(cur)
            q.extend(c.rid for c in self.roles[cur].children)
        return out

    def chain(self, rid):
        """Grant evaluation order: the role itself first, then ancestors."""
        chain = []
        cur = self.roles[rid]
        while cur is not None:
            chain.append(cur.rid)
            cur = cur.parent
        return chain

    def direct_grants(self, rid):
        """Permissions granted directly to rid."""
        return sorted(p for p, holders in self.grants.items() if rid in holders)

    def effective(self, rid):
        return sorted(self.roles[rid].cache)

    def _recompute(self, rid):
        out = set()
        cur = self.roles[rid]
        while cur is not None:
            for p, holders in self.grants.items():
                if cur.rid in holders:
                    out.add(p)
            cur = cur.parent
        return out

    def revoke(self, perm):
        """Strip perm from all holders and their sub-trees; invalidate
        caches accordingly. Returns sorted list of affected roles."""
        holders = sorted(self.grants.get(perm, set()))
        if not holders:
            return []
        del self.grants[perm]
        affected = set()
        for h in holders:
            for rid in self._descendant_ids(h):
                role = self.roles[rid]
                role.cache.discard(perm)
                affected.add(rid)
        return sorted(affected)

    def cache_coherent(self):
        """Invariant: every cached set equals the recomputed truth."""
        for rid, role in self.roles.items():
            if role.cache != self._recompute(rid):
                return False
        return True
