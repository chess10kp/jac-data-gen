"""MatRanc/VerticalTimeline2#25 — delete group, contents, and downstream dependents (OSP)."""

obj TimelineStore {
    has groups: dict[str, Group];
    has items: dict[str, Item];
}

node Group { has gid: str; }
node Item { has iid: str; }

edge ChildOf: Group --> Group {}
edge Contains: Group --> Item {}
edge DependsOn: Item --> Item {}

walker GroupSubtreeCollect {
    has claimed: dict[str, bool] = {};
    has found: list[Group] = [];

    can step with Group entry {
        if here.gid in self.claimed { skip; }
        self.claimed[here.gid] = True;
        self.found.append(here);
        visit [->:ChildOf:->][?:Group];
    }
}

walker DependentCollect {
    has claimed: dict[str, bool] = {};
    has found: list[Item] = [];

    can step with Item entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.found.append(here);
        visit [<-:DependsOn:<-][?:Item];
    }
}

def _wire(
    groups: list[tuple[str, str | None]],
    memberships: list[tuple[str, str]],
    refs: list[tuple[str, str]],
) -> TimelineStore {
    gmap: dict[str, Group] = {};
    imap: dict[str, Item] = {};
    for (gid, _par) in groups {
        if gid not in gmap {
            grp = Group(gid=gid);
            root ++> grp;
            gmap[gid] = grp;
        }
    }
    for (gid, par) in groups {
        if par is None { continue; }
        p = gmap.get(par, None);
        c = gmap.get(gid, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    for (grp_id, item_id) in memberships {
        g = gmap.get(grp_id, None);
        if item_id not in imap {
            it = Item(iid=item_id);
            root ++> it;
            imap[item_id] = it;
        }
        i = imap[item_id];
        if g is not None { g +>:Contains:+> i; }
    }
    for (dep, need) in refs {
        a = imap.get(dep, None);
        b = imap.get(need, None);
        if a is not None and b is not None { a +>:DependsOn:+> b; }
    }
    return TimelineStore(groups=gmap, items=imap);
}

def _depth_for_group(store: TimelineStore, grp: Group) -> int {
    d = 0;
    cur: Group | None = grp;
    while cur is not None {
        par: Group | None = None;
        for p in [cur <-:ChildOf:<-][?:Group] { par = p; }
        if par is None { break; }
        d += 1;
        cur = store.groups.get(par.gid, None);
    }
    return d;
}

def _remove_item(it: Item) {
    for dep in [it <-:DependsOn:<-][?:Item] { dep del ->:DependsOn:-> it; }
    for need in [it ->:DependsOn:->][?:Item] { it del ->:DependsOn:-> need; }
    for g in [it <-:Contains:<-][?:Group] { g del ->:Contains:-> it; }
    del it;
}

def _remove_group(grp: Group) {
    for ch in [grp ->:ChildOf:->][?:Group] { grp del ->:ChildOf:-> ch; }
    for par in [grp <-:ChildOf:<-][?:Group] { par del ->:ChildOf:-> grp; }
    for it in [grp ->:Contains:->][?:Item] { grp del ->:Contains:-> it; }
    del grp;
}

def load_timeline(
    groups: list[tuple[str, str | None]],
    memberships: list[tuple[str, str]],
    refs: list[tuple[str, str]],
) -> TimelineStore {
    return _wire(groups, memberships, refs);
}

def delete_group(store: TimelineStore, group_id: str) -> list[str] {
    start = store.groups.get(group_id, None);
    if start is None { return []; }
    gw = start spawn GroupSubtreeCollect(claimed={}, found=[]);
    doomed_items: dict[str, Item] = {};
    for grp in gw.found {
        for it in [grp ->:Contains:->][?:Item] { doomed_items[it.iid] = it; }
    }
    dep_claimed: dict[str, bool] = {};
    seeds = list(doomed_items.values());
    for seed in seeds {
        dw = seed spawn DependentCollect(claimed=dep_claimed, found=[]);
        dep_claimed = dw.claimed;
        for it in dw.found { doomed_items[it.iid] = it; }
    }
    deleted_ids = sorted(doomed_items.keys());
    for it in doomed_items.values() { _remove_item(it); }
    max_d = 0;
    for grp in gw.found {
        d = _depth_for_group(store, grp);
        if d > max_d { max_d = d; }
    }
    for level in range(max_d, -1, -1) {
        for grp in gw.found {
            if _depth_for_group(store, grp) == level {
                _remove_group(grp);
                store.groups.pop(grp.gid, None);
            }
        }
    }
    for iid in deleted_ids { store.items.pop(iid, None); }
    return deleted_ids;
}

def active_items(store: TimelineStore) -> list[str] {
    return sorted(store.items.keys());
}
