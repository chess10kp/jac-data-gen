"""Access-control system, lifted to OSP.

Roles form an InheritsFrom hierarchy; permissions are nodes linked by
Grants cross-links; each role caches its effective set in a typed field.
Revocation follows the two-phase protocol: a walker collects holders and
their sub-trees once-only, the facade severs Grants edges outside the walk,
and caches are updated per collected role. Cycle policy: the hierarchy is
acyclic by construction; sweeps still carry skip-guards for shared roles.
"""
node Role {
    has rid: str;
    has cache: set[str] = set();
}

node Permission {
    has name: str;
}

"""Role hierarchy: parent +>:InheritsFrom:+> child."""
edge InheritsFrom {}

"""Grant cross-link: role +>:Grants:+> permission."""
edge Grants {}

walker AffectedSweep {
    """BFS-equivalent descent from a permission holder collecting every
    role whose effective set must change (holder subtree)."""
    has claimed: dict[str, bool] = {};
    has affected: set[str] = set();

    can step with Role entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        self.affected.add(here.rid);
        visit [->:InheritsFrom:->];
    }
}

walker RoleAscent {
    """Linear climb over InheritsFrom including the entry role; collects
    evaluation order and the inherited permission truth set in one pass."""
    has order: list[str] = [];
    has perms: set[str] = set();

    can step with Role entry {
        self.order.append(here.rid);
        grants: list[Permission] = [here ->:Grants:->];
        for p in grants {
            pn = p as Permission;
            self.perms.add(pn.name);
        }
        visit [here <-:InheritsFrom:<-] else { disengage; }
    }
}

obj AclSystem {
    """Compatibility facade. Role ids and permission names are public API
    currency; lookup maps are domain state."""
    has by_rid: dict[str, Role] = {};
    has by_perm: dict[str, Permission] = {};

    def add_role(rid: str, parent: str | None = None) -> str {
        if rid in self.by_rid {
            raise ValueError("duplicate role " + rid);
        }
        r := Role(rid=rid);
        if parent is not None {
            p = self.by_rid[parent];
            p +>:InheritsFrom:+> r;
        }
        self.by_rid[rid] = r;
        return rid;
    }

    """Two-phase grant: the walker collects the holder's subtree, then
    caches are extended outside the walk."""
    def grant(rid: str, perm: str) -> None {
        perm_node = self._intern(perm);
        holder = self.by_rid[rid];
        existing: list[Permission] = [holder ->:Grants:->];
        if perm_node not in existing {
            holder +>:Grants:+> perm_node;
        }
        w: AffectedSweep = holder spawn AffectedSweep();
        for t in w.affected {
            self.by_rid[t].cache.add(perm);
        }
    }

    """Observable evaluation order: self first, then ancestors."""
    def chain(rid: str) -> list[str] {
        # observable evaluation order: self first, then ancestors
        w = self.by_rid[rid] spawn RoleAscent();
        return w.order;
    }

    def direct_grants(rid: str) -> list[str] {
        perms = [self.by_rid[rid] ->:Grants:->];
        names: list[str] = [];
        for p in perms {
            pn = p as Permission;
            names.append(pn.name);
        }
        return sorted(names);
    }

    def effective(rid: str) -> list[str] {
        return sorted(self.by_rid[rid].cache);
    }

    """Two-phase revoke. Phase 1 collects every affected role from each
    holder's subtree; phase 2 severs Grants edges and updates caches."""
    def revoke(perm: str) -> list[str] {
        perm_node = self.by_perm.get(perm);
        if perm_node is None {
            return [];
        }
        holder_list: list[Role] = [perm_node <-:Grants:<-];
        affected: set[str] = set();
        for h in holder_list {
            w = h spawn AffectedSweep();
            affected |= w.affected;
        }
        for h in holder_list {
            h del ->:Grants:-> perm_node;
        }
        self.by_perm.pop(perm);
        for rid in affected {
            self.by_rid[rid].cache.discard(perm);
        }
        return sorted(affected);
    }

    """Invariant probe: cached sets must equal recomputed truth."""
    def cache_coherent() -> bool {
        for rid in self.by_rid.keys() {
            w = self.by_rid[rid] spawn RoleAscent();
            if self.by_rid[rid].cache != w.perms {
                return False;
            }
        }
        return True;
    }

    def _intern(name: str) -> Permission {
        p = self.by_perm.get(name);
        if p is None {
            p = Permission(name=name);
            self.by_perm[name] = p;
        }
        return p;
    }
}
