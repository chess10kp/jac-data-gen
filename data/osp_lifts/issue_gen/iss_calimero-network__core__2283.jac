"""calimero-network/core#2283 — leave_namespace cascade (OSP lift)."""

obj NamespaceStore { has groups: dict[str, Group] = {}; }

node Group {
    has gid: str;
    has members: list[str] = [];
}

edge ChildOf {}

walker SubtreeCollect {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Group entry {
        if here.gid in self.claimed { skip; }
        self.claimed[here.gid] = True;
        self.reached.append(here.gid);
        for ch in [here ->:ChildOf:->][?:Group] {
            visit [ch];
        }
    }
}

def load_namespace(
    groups: list[str],
    parent_edges: list[tuple[str, str]],
    members: list[tuple[str, str]],
) -> NamespaceStore {
    ns = NamespaceStore();
    for gid in groups {
        if gid not in ns.groups {
            g = Group(gid=gid);
            root ++> g;
            ns.groups[gid] = g;
        }
    }
    for (parent, child) in parent_edges {
        p = ns.groups.get(parent, None);
        c = ns.groups.get(child, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    for (gid, user) in members {
        g: Group | None = ns.groups.get(gid, None);
        if g is not None and user not in g.members {
            g.members = g.members + [user];
        }
    }
    return ns;
}

def _subtree_ids(ns: NamespaceStore, root_id: str) -> list[str] {
    anchor = ns.groups.get(root_id, None);
    if anchor is None { return []; }
    w = anchor spawn SubtreeCollect(claimed={}, reached=[]);
    return w.reached;
}

def scopes_for_member(ns: NamespaceStore, user: str, root_id: str) -> list[str] {
    scopes: list[str] = [];
    for gid in _subtree_ids(ns, root_id) {
        g = ns.groups[gid];
        if user in g.members { scopes.append(gid); }
    }
    return sorted(scopes);
}

def leave_namespace(ns: NamespaceStore, user: str, root_id: str) -> list[str] {
    targets = scopes_for_member(ns, user, root_id);
    removed: list[str] = [];
    for gid in targets {
        g = ns.groups[gid];
        if user in g.members {
            g.members = [m for m in g.members if m != user];
            removed.append(gid);
        }
    }
    return sorted(removed);
}

def member_groups(ns: NamespaceStore, user: str) -> list[str] {
    out: list[str] = [];
    for gid in sorted(ns.groups.keys()) {
        if user in ns.groups[gid].members { out.append(gid); }
    }
    return out;
}

def orphaned_memberships(ns: NamespaceStore, user: str, root_id: str) -> list[str] {
    root_g = ns.groups.get(root_id, None);
    if root_g is None { return []; }
    root_scopes = set(_subtree_ids(ns, root_id));
    bad: list[str] = [];
    for gid in sorted(root_scopes) {
        g = ns.groups[gid];
        if user in g.members and user not in root_g.members { bad.append(gid); }
    }
    return bad;
}
