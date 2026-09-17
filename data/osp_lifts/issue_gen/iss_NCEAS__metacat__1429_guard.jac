# NCEAS/metacat#1429 — closure table for version chains (OSP lift).

node Catalog {
    has name: str = "versions";
}

node Version {
    has guid: str;
}

edge InCatalog {}
edge Obsoletes {}

walker NewerReach {
    has anchor: str;
    has found: list[list] = [];
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};

    can expand with Version entry {
        if here.guid in self.claimed {
            skip;
        }
        self.claimed[here.guid] = True;
        if here.guid not in self.depths {
            self.depths[here.guid] = 0;
        }
        d: int = self.depths[here.guid];
        row: list = [self.anchor, here.guid, d];
        self.found.append(row);
        kids: list[Version] = [here <-:Obsoletes:<-][?:Version];
        kids = _sort_versions(kids);
        nd: int = d + 1;
        for kid in kids {
            if kid.guid not in self.depths {
                self.depths[kid.guid] = nd;
            }
        }
        if kids {
            visit :0: kids;
        }
    }
}

walker CanReach {
    has target: str;
    has claimed: dict[str, bool] = {};
    has ok: bool = False;

    can probe with Version entry {
        if here.guid in self.claimed {
            skip;
        }
        self.claimed[here.guid] = True;
        if here.guid == self.target {
            self.ok = True;
        }
        newer: list[Version] = [here <-:Obsoletes:<-][?:Version];
        newer = _sort_versions(newer);
        if newer {
            visit :0: newer;
        }
    }
}

walker WalkNewer {
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};
    has target: str = "";

    can step with Version entry {
        if here.guid in self.claimed {
            skip;
        }
        self.claimed[here.guid] = True;
        self.chain.append(here.guid);
        newer: list[Version] = [here <-:Obsoletes:<-][?:Version];
        nxt = _pick_successor(newer, self.target);
        if nxt {
            visit :0: [nxt];
        }
    }
}

def _sort_versions(vs: list[Version]) -> list[Version] {
    out: list[Version] = [];
    for v in vs {
        out.append(v);
    }
    i: int = 0;
    while i < len(out) {
        j: int = i + 1;
        while j < len(out) {
            if out[j].guid < out[i].guid {
                tmp: Version = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def _pick_successor(candidates: list[Version], target: str) -> Version | None {
    if not candidates {
        return None;
    }
    sorted_c: list[Version] = _sort_versions(candidates);
    if len(sorted_c) == 1 {
        return sorted_c[0];
    }
    chosen: Version | None = None;
    for n in sorted_c {
        cr = n spawn CanReach(target=target, claimed={});
        if cr.ok {
            chosen = n;
            break;
        }
    }
    if not chosen {
        chosen = sorted_c[0];
    }
    return chosen;
}

def _versions_under(cat: Catalog) -> list[Version] {
    return [cat ->:InCatalog:->][?:Version];
}

def _find_version(cat: Catalog, guid: str) -> Version | None {
    for v in _versions_under(cat) {
        if v.guid == guid {
            return v;
        }
    }
    return None;
}

def _oldest_from(v: Version) -> Version {
    cur: Version = v;
    while True {
        older: list[Version] = [cur ->:Obsoletes:->][?:Version];
        older = _sort_versions(older);
        if older {
            cur = older[0];
        } else {
            break;
        }
    }
    return cur;
}

def build_version_graph(specs: list) -> Catalog {
    cat = Catalog();
    root ++> cat;
    by_guid: dict[str, Version] = {};
    for spec in specs {
        g: str = spec["guid"];
        nd = Version(guid=g);
        by_guid[g] = nd;
        cat +>:InCatalog:+> nd;
    }
    for spec in specs {
        g: str = spec["guid"];
        newer: Version = by_guid[g];
        targets: list = [];
        if "obsoletes" in spec {
            ob: any = spec["obsoletes"];
            if ob is str {
                targets.append(ob);
            } else {
                for t in ob {
                    targets.append(t);
                }
            }
        }
        for og in targets {
            if og in by_guid {
                older: Version = by_guid[og];
                newer +>:Obsoletes:+> older;
            }
        }
    }
    return cat;
}

def closure_table(cat: Catalog) -> list[list] {
    rows: list[list] = [];
    for v in _versions_under(cat) {
        depths: dict[str, int] = {};
        depths[v.guid] = 0;
        w = v spawn NewerReach(
            anchor=v.guid,
            claimed={},
            depths=depths
        );
        for r in w.found {
            rows.append(r);
        }
    }
    return sorted(rows);
}

def versions_for(cat: Catalog, guid: str) -> list[str] {
    if not _find_version(cat, guid) {
        return [];
    }
    seen: dict[str, bool] = {};
    for row in closure_table(cat) {
        p: str = row[0];
        c: str = row[1];
        if p == guid {
            seen[c] = True;
        }
        if c == guid {
            seen[p] = True;
        }
    }
    seen[guid] = True;
    out: list[str] = [];
    for k in seen {
        out.append(k);
    }
    return sorted(out);
}

def chain_from_oldest(cat: Catalog, guid: str) -> list[str] {
    v = _find_version(cat, guid);
    if not v {
        return [];
    }
    start: Version = _oldest_from(v);
    wk = start spawn WalkNewer(claimed={}, target=guid);
    return wk.chain;
}

with entry {
    demo_specs: list = [
        {"guid": "v1"},
        {"guid": "v2", "obsoletes": "v1"},
        {"guid": "v3", "obsoletes": "v2"}
    ];
    demo_cat = build_version_graph(demo_specs);
    v1n = _find_version(demo_cat, "v1");
    w = v1n spawn NewerReach(
        anchor="v1",
        claimed={},
        depths={"v1": 0}
    );
    print(w.found);
}

# NCEAS/metacat#1429 — closure table for version chains (OSP lift).

node Catalog {
    has name: str = "versions";
}

node Version {
    has guid: str;
}

edge InCatalog {}
edge Obsoletes {}

walker NewerReach {
    has anchor: str;
    has found: list[list] = [];
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};

    can expand with Version entry {
        if here.guid in self.claimed {
            skip;
        }
        self.claimed[here.guid] = True;
        if here.guid not in self.depths {
            self.depths[here.guid] = 0;
        }
        d: int = self.depths[here.guid];
        row: list = [self.anchor, here.guid, d];
        self.found.append(row);
        kids: list[Version] = [here <-:Obsoletes:<-][?:Version];
        kids = _sort_versions(kids);
        nd: int = d + 1;
        for kid in kids {
            if kid.guid not in self.depths {
                self.depths[kid.guid] = nd;
            }
        }
        if kids {
            visit :0: kids;
        }
    }
}

walker CanReach {
    has target: str;
    has claimed: dict[str, bool] = {};
    has ok: bool = False;

    can probe with Version entry {
        if here.guid in self.claimed {
            skip;
        }
        self.claimed[here.guid] = True;
        if here.guid == self.target {
            self.ok = True;
        }
        newer: list[Version] = [here <-:Obsoletes:<-][?:Version];
        newer = _sort_versions(newer);
        if newer {
            visit :0: newer;
        }
    }
}

walker WalkNewer {
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};
    has target: str = "";

    can step with Version entry {
        if here.guid in self.claimed {
            skip;
        }
        self.claimed[here.guid] = True;
        self.chain.append(here.guid);
        newer: list[Version] = [here <-:Obsoletes:<-][?:Version];
        nxt = _pick_successor(newer, self.target);
        if nxt {
            visit :0: [nxt];
        }
    }
}

def _sort_versions(vs: list[Version]) -> list[Version] {
    out: list[Version] = [];
    for v in vs {
        out.append(v);
    }
    i: int = 0;
    while i < len(out) {
        j: int = i + 1;
        while j < len(out) {
            if out[j].guid < out[i].guid {
                tmp: Version = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def _pick_successor(candidates: list[Version], target: str) -> Version | None {
    if not candidates {
        return None;
    }
    sorted_c: list[Version] = _sort_versions(candidates);
    if len(sorted_c) == 1 {
        return sorted_c[0];
    }
    chosen: Version | None = None;
    for n in sorted_c {
        cr = n spawn CanReach(target=target, claimed={});
        if cr.ok {
            chosen = n;
            break;
        }
    }
    if not chosen {
        chosen = sorted_c[0];
    }
    return chosen;
}

def _versions_under(cat: Catalog) -> list[Version] {
    return [cat ->:InCatalog:->][?:Version];
}

def _find_version(cat: Catalog, guid: str) -> Version | None {
    for v in _versions_under(cat) {
        if v.guid == guid {
            return v;
        }
    }
    return None;
}

def _oldest_from(v: Version) -> Version {
    cur: Version = v;
    while True {
        older: list[Version] = [cur ->:Obsoletes:->][?:Version];
        older = _sort_versions(older);
        if older {
            cur = older[0];
        } else {
            break;
        }
    }
    return cur;
}

def build_version_graph(specs: list) -> Catalog {
    cat = Catalog();
    root ++> cat;
    by_guid: dict[str, Version] = {};
    for spec in specs {
        g: str = spec["guid"];
        nd = Version(guid=g);
        by_guid[g] = nd;
        cat +>:InCatalog:+> nd;
    }
    for spec in specs {
        g: str = spec["guid"];
        newer: Version = by_guid[g];
        targets: list = [];
        if "obsoletes" in spec {
            ob: any = spec["obsoletes"];
            if ob is str {
                targets.append(ob);
            } else {
                for t in ob {
                    targets.append(t);
                }
            }
        }
        for og in targets {
            if og in by_guid {
                older: Version = by_guid[og];
                newer +>:Obsoletes:+> older;
            }
        }
    }
    return cat;
}

def closure_table(cat: Catalog) -> list[list] {
    rows: list[list] = [];
    for v in _versions_under(cat) {
        depths: dict[str, int] = {};
        depths[v.guid] = 0;
        w = v spawn NewerReach(
            anchor=v.guid,
            claimed={},
            depths=depths
        );
        for r in w.found {
            rows.append(r);
        }
    }
    return sorted(rows);
}

def versions_for(cat: Catalog, guid: str) -> list[str] {
    if not _find_version(cat, guid) {
        return [];
    }
    seen: dict[str, bool] = {};
    for row in closure_table(cat) {
        p: str = row[0];
        c: str = row[1];
        if p == guid {
            seen[c] = True;
        }
        if c == guid {
            seen[p] = True;
        }
    }
    seen[guid] = True;
    out: list[str] = [];
    for k in seen {
        out.append(k);
    }
    return sorted(out);
}

def chain_from_oldest(cat: Catalog, guid: str) -> list[str] {
    v = _find_version(cat, guid);
    if not v {
        return [];
    }
    start: Version = _oldest_from(v);
    wk = start spawn WalkNewer(claimed={}, target=guid);
    return wk.chain;
}

test "linear_closure_rows" {
    specs: list = [
        {"guid": "v1"},
        {"guid": "v2", "obsoletes": "v1"},
        {"guid": "v3", "obsoletes": "v2"}
    ];
    cat = build_version_graph(specs);
    got = closure_table(cat);
    exp: list[list] = [
        ["v1", "v1", 0],
        ["v1", "v2", 1],
        ["v1", "v3", 2],
        ["v2", "v2", 0],
        ["v2", "v3", 1],
        ["v3", "v3", 0]
    ];
    assert got == exp;
}

test "diamond_revisit_skip" {
    specs: list = [
        {"guid": "v1"},
        {"guid": "v2", "obsoletes": "v1"},
        {"guid": "v3", "obsoletes": "v1"},
        {"guid": "v4", "obsoletes": ["v2", "v3"]}
    ];
    cat = build_version_graph(specs);
    got = closure_table(cat);
    exp: list[list] = [
        ["v1", "v1", 0],
        ["v1", "v2", 1],
        ["v1", "v3", 1],
        ["v1", "v4", 2],
        ["v2", "v2", 0],
        ["v2", "v4", 1],
        ["v3", "v3", 0],
        ["v3", "v4", 1],
        ["v4", "v4", 0]
    ];
    assert got == exp;
}

test "chain_from_oldest_order" {
    specs: list = [
        {"guid": "v1"},
        {"guid": "v2", "obsoletes": "v1"},
        {"guid": "v3", "obsoletes": "v2"}
    ];
    cat = build_version_graph(specs);
    assert chain_from_oldest(cat, "v2") == ["v1", "v2", "v3"];
}

test "versions_for_linear" {
    specs: list = [
        {"guid": "v1"},
        {"guid": "v2", "obsoletes": "v1"},
        {"guid": "v3", "obsoletes": "v2"}
    ];
    cat = build_version_graph(specs);
    assert versions_for(cat, "v2") == ["v1", "v2", "v3"];
}

test "missing_guid_empty" {
    specs: list = [{"guid": "v1"}];
    cat = build_version_graph(specs);
    assert chain_from_oldest(cat, "missing") == [];
    assert versions_for(cat, "missing") == [];
}
