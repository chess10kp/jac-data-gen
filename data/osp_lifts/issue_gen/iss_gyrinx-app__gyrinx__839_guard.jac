"""gyrinx-app/gyrinx#839 — batch equipment category restriction filtering."""

node EquipCategory {
    has cid: str;
    has name: str = "";
}

node FighterCat {
    has fid: str;
}

edge CatChild {}
edge CatRestrict {}

walker RestrictWalk {
    has claimed: dict[str, bool] = {};
    has target_fid: str = "";
    has restricted: list[str] = [];

    can step with EquipCategory entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for fc in [here ->:CatRestrict:->][?:FighterCat] {
            if fc.fid == self.target_fid { self.restricted.append(here.cid); }
        }
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: EquipCategory) -> list[EquipCategory] {
    kids: list[EquipCategory] = [];
    for ch in [nd ->:CatChild:->][?:EquipCategory] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.cid); }
    names = sorted(names);
    ordered: list[EquipCategory] = [];
    for nm in names { for ch in kids { if ch.cid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_category(cid: str, store: dict) -> EquipCategory | None {
    nmap = store["nodes"] as dict[str, EquipCategory];
    if cid in nmap { return nmap[cid]; }
    return None;
}

def _find_fighter(fid: str, store: dict) -> FighterCat | None {
    fmap = store["fighters"] as dict[str, FighterCat];
    if fid in fmap { return fmap[fid]; }
    return None;
}

def fresh_gear_store() -> dict {
    return {"categories": {}, "fighters": {}, "deps": {}, "nodes": {}, "roots": []};
}

def register_category(cat_id: str, name: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_gear_store(); }
    (s["categories"] as dict[str, str])[cat_id] = name;
    deps = s["deps"] as dict[str, list[str]];
    if cat_id not in deps { deps[cat_id] = []; }
    nd = EquipCategory(cid=cat_id, name=name);
    root ++> nd;
    roots = s["roots"] as list[str];
    roots.append(cat_id);
    (s["nodes"] as dict[str, EquipCategory])[cat_id] = nd;
    return s;
}

def register_fighter_category(fid: str, store: dict) -> dict {
    if fid in (store["fighters"] as dict) { return store; }
    fc = FighterCat(fid=fid);
    root ++> fc;
    (store["fighters"] as dict[str, FighterCat])[fid] = fc;
    return store;
}

def add_cat_child(source_id: str, target_id: str, store: dict) {
    cmap = store["categories"] as dict[str, str];
    if source_id not in cmap or target_id not in cmap { raise KeyError("unknown category id"); }
    if source_id == target_id { return; }
    src_nd = _find_category(source_id, store);
    tgt_nd = _find_category(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:CatChild:->][?:EquipCategory] { if ex.cid == target_id { seen = True; } }
        if not seen { src_nd +>:CatChild:+> tgt_nd; }
        roots = store["roots"] as list[str];
        if target_id in roots { roots.remove(target_id); }
    }
    outs = store["deps"] as dict[str, list[str]];
    if source_id not in outs { outs[source_id] = []; }
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
}

def add_fighter_restriction(cat_id: str, fighter_cat_id: str, store: dict) {
    if cat_id not in (store["categories"] as dict) { raise KeyError(cat_id); }
    register_fighter_category(fighter_cat_id, store);
    cat_nd = _find_category(cat_id, store);
    fc_nd = _find_fighter(fighter_cat_id, store);
    if cat_nd is not None and fc_nd is not None {
        seen = False;
        for ex in [cat_nd ->:CatRestrict:->][?:FighterCat] { if ex.fid == fighter_cat_id { seen = True; } }
        if not seen { cat_nd +>:CatRestrict:+> fc_nd; }
    }
}

def prefetch_restricted_ids(fighter_cat_id: str, store: dict) -> list[str] {
    register_fighter_category(fighter_cat_id, store);
    restricted: list[str] = [];
    roots = store["roots"] as list[str];
    for rid in sorted(roots) {
        nd = _find_category(rid, store);
        if nd is None { continue; }
        w = nd spawn RestrictWalk(target_fid=fighter_cat_id, claimed={}, restricted=[]);
        for cid in w.restricted { if cid not in restricted { restricted.append(cid); } }
    }
    restricted = sorted(restricted);
    return restricted;
}

def restricted_category_ids(fighter_cat_id: str, cat_ids: list[str], store: dict) -> list[str] {
    cmap = store["categories"] as dict[str, str];
    for cid in cat_ids { if cid not in cmap { raise KeyError(cid); } }
    pref = prefetch_restricted_ids(fighter_cat_id, store);
    blocked: list[str] = [];
    for cid in cat_ids { if cid in pref { blocked.append(cid); } }
    blocked = sorted(blocked);
    return blocked;
}

def restriction_report(fighter_cat_id: str, cat_ids: list[str], store: dict) -> dict {
    blocked = restricted_category_ids(fighter_cat_id, cat_ids, store);
    pref = prefetch_restricted_ids(fighter_cat_id, store);
    allowed: list[str] = [];
    for cid in cat_ids { if cid not in blocked { allowed.append(cid); } }
    allowed = sorted(allowed);
    return {"blocked": blocked, "allowed": allowed, "prefetch_count": len(pref), "query_count": 1};
}

test "diamond revisit keeps single shared leaf category" {
    s = fresh_gear_store();
    register_category("melee", "Melee", s);
    register_category("ranged", "Ranged", s);
    register_category("special", "Special", s);
    register_category("heavy", "Heavy", s);
    add_cat_child("melee", "special", s);
    add_cat_child("melee", "ranged", s);
    add_cat_child("ranged", "heavy", s);
    add_cat_child("special", "heavy", s);
    register_fighter_category("infantry", s);
    add_fighter_restriction("heavy", "infantry", s);
    pref = prefetch_restricted_ids("infantry", s);
    assert pref == ["heavy"];
    got = restricted_category_ids("infantry", ["melee", "ranged", "special", "heavy"], s);
    assert got == ["heavy"];
}

test "adversarial edge insertion order is stable" {
    s1 = fresh_gear_store();
    register_category("melee", "Melee", s1);
    register_category("ranged", "Ranged", s1);
    register_category("special", "Special", s1);
    register_category("heavy", "Heavy", s1);
    add_cat_child("melee", "special", s1);
    add_cat_child("special", "heavy", s1);
    add_cat_child("melee", "ranged", s1);
    add_cat_child("ranged", "heavy", s1);
    register_fighter_category("infantry", s1);
    add_fighter_restriction("heavy", "infantry", s1);
    s2 = fresh_gear_store();
    register_category("melee", "Melee", s2);
    register_category("ranged", "Ranged", s2);
    register_category("special", "Special", s2);
    register_category("heavy", "Heavy", s2);
    add_cat_child("melee", "ranged", s2);
    add_cat_child("ranged", "heavy", s2);
    add_cat_child("melee", "special", s2);
    add_cat_child("special", "heavy", s2);
    register_fighter_category("infantry", s2);
    add_fighter_restriction("heavy", "infantry", s2);
    assert prefetch_restricted_ids("infantry", s1) == prefetch_restricted_ids("infantry", s2);
}

test "unknown category ids raise KeyError" {
    s = fresh_gear_store();
    register_category("melee", "Melee", s);
    register_fighter_category("infantry", s);
    caught = False;
    try { add_cat_child("melee", "missing", s); } except KeyError { caught = True; }
    assert caught;
    caught2 = False;
    try { restricted_category_ids("infantry", ["missing"], s); } except KeyError { caught2 = True; }
    assert caught2;
}

test "prefetch batch avoids per category lookup" {
    s = fresh_gear_store();
    register_category("melee", "Melee", s);
    register_category("ranged", "Ranged", s);
    register_category("special", "Special", s);
    register_fighter_category("infantry", s);
    register_fighter_category("vehicle", s);
    add_fighter_restriction("melee", "infantry", s);
    add_fighter_restriction("special", "infantry", s);
    add_fighter_restriction("ranged", "vehicle", s);
    blocked = restricted_category_ids("infantry", ["melee", "ranged", "special"], s);
    assert blocked == ["melee", "special"];
    rep = restriction_report("infantry", ["melee", "ranged", "special"], s);
    assert rep["allowed"] == ["ranged"];
    assert rep["query_count"] == 1;
    assert rep["prefetch_count"] == 2;
}

test "unrestricted categories remain available" {
    s = fresh_gear_store();
    register_category("melee", "Melee", s);
    register_category("ranged", "Ranged", s);
    register_fighter_category("infantry", s);
    add_fighter_restriction("melee", "vehicle", s);
    got = restricted_category_ids("infantry", ["melee", "ranged"], s);
    assert got == [];
    rep = restriction_report("infantry", ["melee", "ranged"], s);
    assert rep["blocked"] == [];
    assert rep["allowed"] == ["melee", "ranged"];
}
