"""Lindenfrost/ProgTrack-Release#186 — bounded pedigree scope and sibling ghost closure."""

node Animal {
    has cid: str;
    has archived: bool = False;
}

edge Parent {}

node HeritageHub {
    has members: dict[str, Animal] = {};
}

walker ScopeWalker {
    has claimed: dict[str, bool] = {};
    has limit: int = 0;
    has seeds: list[str] = [];
    has include_archived: bool = True;
    has found: list[str] = [];
    has depth_by: dict[str, int] = {};

    can boot with HeritageHub entry {
        root spawn ScopeWalker(
            claimed={},
            limit=self.limit,
            seeds=self.seeds,
            include_archived=self.include_archived,
            found=[],
            depth_by={}
        );
        print("scope_walk_boot");
        for sid in self.seeds {
            if sid not in here.members {
                continue;
            }
            nd = here.members[sid] as Animal;
            self.depth_by[sid] = 0;
            visit :0: [nd];
        }
    }

    can ascend with Animal entry {
        if here.cid in self.claimed {
            skip;
        }
        cur: int = 0;
        if here.cid in self.depth_by {
            cur = self.depth_by[here.cid];
        }
        if cur > self.limit {
            disengage;
        }
        if not self.include_archived and here.archived {
            disengage;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        parents: list[Animal] = [];
        for p in [here <-:Parent:<-][?:Animal] {
            parents.append(p);
        }
        for p in parents {
            nd: int = cur + 1;
            self.depth_by[p.cid] = nd;
            visit :0: [p];
        }
    }
}

def build_fixture -> HeritageHub {
    hub = HeritageHub();
    root ++> hub;
    finwe = Animal(cid="finwe", archived=False);
    elrond = Animal(cid="elrond", archived=False);
    elros = Animal(cid="elros", archived=False);
    arwen = Animal(cid="arwen", archived=False);
    beth = Animal(cid="beth", archived=False);
    denethor = Animal(cid="denethor", archived=False);
    eldarion = Animal(cid="eldarion", archived=False);
    archived_sib = Animal(cid="archived_sib", archived=True);
    root ++> finwe;
    root ++> elrond;
    root ++> elros;
    root ++> arwen;
    root ++> beth;
    root ++> denethor;
    root ++> eldarion;
    root ++> archived_sib;
    hub.members["finwe"] = finwe;
    hub.members["elrond"] = elrond;
    hub.members["elros"] = elros;
    hub.members["arwen"] = arwen;
    hub.members["beth"] = beth;
    hub.members["denethor"] = denethor;
    hub.members["eldarion"] = eldarion;
    hub.members["archived_sib"] = archived_sib;
    finwe +>:Parent:+> elrond;
    finwe +>:Parent:+> elros;
    finwe +>:Parent:+> archived_sib;
    elrond +>:Parent:+> arwen;
    elros +>:Parent:+> denethor;
    beth +>:Parent:+> denethor;
    denethor +>:Parent:+> eldarion;
    return hub;
}

def build_diamond_fixture -> HeritageHub {
    hub = HeritageHub();
    root ++> hub;
    gp = Animal(cid="gp", archived=False);
    p2 = Animal(cid="p2", archived=False);
    p1 = Animal(cid="p1", archived=False);
    kid = Animal(cid="kid", archived=False);
    root ++> gp;
    root ++> p2;
    root ++> p1;
    root ++> kid;
    hub.members["gp"] = gp;
    hub.members["p2"] = p2;
    hub.members["p1"] = p1;
    hub.members["kid"] = kid;
    p2 +>:Parent:+> gp;
    p1 +>:Parent:+> gp;
    kid +>:Parent:+> p2;
    kid +>:Parent:+> p1;
    return hub;
}

def expand_ancestors(hub: HeritageHub, selected: list[str], depth: int, include_archived: bool = True) -> list[str] {
    w = hub spawn ScopeWalker(
        claimed={},
        limit=depth,
        seeds=selected,
        include_archived=include_archived,
        found=[],
        depth_by={}
    );
    return sorted(w.found);
}

def sibling_ghosts_for_scope(hub: HeritageHub, scope_ids: list[str]) -> list[str] {
    scope_set: dict[str, bool] = {};
    for sid in scope_ids {
        scope_set[sid] = True;
    }
    ghosts: list[str] = [];
    ghost_set: dict[str, bool] = {};
    for sid in sorted(scope_ids) {
        if sid not in hub.members {
            continue;
        }
        animal = hub.members[sid] as Animal;
        parents: list[Animal] = [];
        for p in [animal <-:Parent:<-][?:Animal] {
            parents.append(p);
        }
        for p in parents {
            sibs: list[Animal] = [];
            for ch in [p ->:Parent:->][?:Animal] {
                sibs.append(ch);
            }
            for sib in sibs {
                scid = sib.cid;
                if scid in scope_set {
                    continue;
                }
                if scid in ghost_set {
                    continue;
                }
                ghost_set[scid] = True;
                ghosts.append(scid);
            }
        }
    }
    return sorted(ghosts);
}

def effective_display_nodes(hub: HeritageHub, selected: list[str], depth: int, include_archived: bool = True) -> list[str] {
    ancestors = expand_ancestors(hub, selected, depth, include_archived);
    ghosts = sibling_ghosts_for_scope(hub, ancestors);
    merged: list[str] = [];
    seen: dict[str, bool] = {};
    for cid in ancestors {
        if cid in seen {
            continue;
        }
        seen[cid] = True;
        merged.append(cid);
    }
    for gid in ghosts {
        if gid in seen {
            continue;
        }
        seen[gid] = True;
        merged.append(gid);
    }
    return sorted(merged);
}
