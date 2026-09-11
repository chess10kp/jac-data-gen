"""l3montree-dev/devguard#2780 — content-addressed Merkle SBOM store (OSP lift)."""

obj MerkleStore { has stamp: int = 0; }

node Component {
    has purl: str;
    has name: str;
    has subtree_hash: str = "";
}

node SbomSource {
    has asset_id: str;
    has version: str;
    has origin: str;
    has root_purl: str;
    has root_hash: str = "";
}

node MerkleEdgeRow {
    has subtree_hash: str;
    has component_id: str;
    has child_subtree_hash: str;
}

edge Depends {}

def fold_hash(purl: str, child_hashes: list[str]) -> str {
    h = 0;
    i = 0;
    while i < len(purl) {
        h = (h * 31 + ord(purl[i])) & 0xFFFFFFFF;
        i += 1;
    }
    for chh in sorted(child_hashes) {
        h = (h * 31 + int(chh)) & 0xFFFFFFFF;
    }
    return str(h);
}

def _sort_by_purl(nodes: list[Component]) -> list[Component] {
    out = list(nodes);
    i = 0;
    while i < len(out) {
        j = i + 1;
        while j < len(out) {
            if out[j].purl < out[i].purl {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def _find_comp(purl: str) -> Component | None {
    for c in [-->][?:Component] {
        if c.purl == purl { return c; }
    }
    return None;
}

def _find_source(asset_id: str, version: str, origin: str) -> SbomSource | None {
    for s in [-->][?:SbomSource] {
        if s.asset_id == asset_id {
            if s.version == version {
                if s.origin == origin { return s; }
            }
        }
    }
    return None;
}

def _edge_key_seen(key: str) -> bool {
    for row in [-->][?:MerkleEdgeRow] {
        k = row.subtree_hash + "|" + row.component_id + "|" + row.child_subtree_hash;
        if k == key { return True; }
    }
    return False;
}

walker HashPost {
    has start_purl: str = "";
    has claimed: dict[str, bool] = {};
    has visiting: dict[str, bool] = {};

    can begin with Root entry {
        target = self.start_purl;
        if target == "" { target = "ROOT"; }
        for c in [-->][?:Component] {
            if c.purl == target { visit [c]; }
        }
    }

    can step with Component entry {
        if here.purl in self.claimed { skip; }
        if here.purl in self.visiting { skip; }
        self.visiting[here.purl] = True;
        visit [here->:Depends:->][?:Component];
    }

    can leave with Component exit {
        self.visiting.pop(here.purl, None);
        if here.purl in self.claimed { skip; }
        ch_hashes = [];
        for ch in _sort_by_purl([here->:Depends:->][?:Component]) {
            ch_hashes.append(ch.subtree_hash);
        }
        here.subtree_hash = fold_hash(here.purl, ch_hashes);
        self.claimed[here.purl] = True;
    }
}

walker DownClosure {
    has start_purl: str;
    has claimed: dict[str, bool] = {};
    has purls: list[str] = [];

    can begin with Root entry {
        for c in [-->][?:Component] {
            if c.purl == self.start_purl { visit [c]; }
        }
    }

    can step with Component entry {
        if here.purl in self.claimed { skip; }
        self.claimed[here.purl] = True;
        self.purls.append(here.purl);
        visit [here->:Depends:->][?:Component];
    }

    can finish with Root exit { report self.purls; }
}

walker UpStep {
    has cur_hash: str;
    has claimed: dict[str, bool] = {};
    has root_hashes: list[str] = [];

    can begin with Root entry {
        if self.cur_hash in self.claimed { disengage; }
        self.claimed[self.cur_hash] = True;
        visit [-->][?:MerkleEdgeRow];
    }

    can on_row with MerkleEdgeRow entry {
        if here.child_subtree_hash != self.cur_hash { skip; }
        parent_hash = here.subtree_hash;
        if here.component_id == "ROOT" {
            self.root_hashes.append(parent_hash);
            disengage;
        }
        if parent_hash in self.claimed { skip; }
        w = root spawn UpStep(cur_hash=parent_hash, claimed=self.claimed, root_hashes=[]);
        for rh in w.root_hashes {
            found = False;
            for existing in self.root_hashes {
                if existing == rh { found = True; }
            }
            if not found { self.root_hashes.append(rh); }
        }
    }
}

def load_sbom(
    components: list[tuple[str, str]],
    deps: list[tuple[str, str]],
    sources: list[tuple[str, str, str, str]],
) -> MerkleStore {
    mp: dict[str, Component] = {};
    for (purl, name) in components {
        if purl not in mp {
            c = Component(purl=purl, name=name);
            root ++> c;
            mp[purl] = c;
        }
    }
    for (parent, child) in deps {
        p = mp.get(parent, None);
        ch = mp.get(child, None);
        if p is not None {
            if ch is not None { p +>:Depends:+> ch; }
        }
    }
    for (asset_id, version, origin, root_purl) in sources {
        s = SbomSource(
            asset_id=asset_id, version=version, origin=origin, root_purl=root_purl,
        );
        root ++> s;
    }
    return MerkleStore(stamp=1);
}

def subtree_hash(store: MerkleStore, purl: str) -> str {
    _ = store;
    c = _find_comp(purl);
    if c is None { return ""; }
    if c.subtree_hash != "" { return c.subtree_hash; }
    root spawn HashPost(start_purl=purl, claimed={}, visiting={});
    return c.subtree_hash;
}

def ingest_edges(store: MerkleStore) -> int {
    _ = store;
    before = 0;
    for _ in [-->][?:MerkleEdgeRow] { before += 1; }
    root spawn HashPost(start_purl="", claimed={}, visiting={});
    root_c = _find_comp("ROOT");
    root_h = "";
    if root_c is not None { root_h = root_c.subtree_hash; }
    for s in [-->][?:SbomSource] { s.root_hash = root_h; }
    for c in [-->][?:Component] {
        for ch in [c->:Depends:->][?:Component] {
            key = c.subtree_hash + "|" + c.purl + "|" + ch.subtree_hash;
            if not _edge_key_seen(key) {
                row = MerkleEdgeRow(
                    subtree_hash=c.subtree_hash,
                    component_id=c.purl,
                    child_subtree_hash=ch.subtree_hash,
                );
                root ++> row;
            }
        }
    }
    after = 0;
    for _ in [-->][?:MerkleEdgeRow] { after += 1; }
    return after - before;
}

def transitive_deps(
    store: MerkleStore, asset_id: str, version: str, origin: str,
) -> list[str] {
    _ = store;
    src = _find_source(asset_id, version, origin);
    if src is None { return []; }
    w = root spawn DownClosure(start_purl=src.root_purl, claimed={}, purls=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def artifacts_with_component(store: MerkleStore, purl: str) -> list[tuple[str, str, str]] {
    _ = store;
    comp = _find_comp(purl);
    if comp is None { return []; }
    seeds: list[str] = [];
    for row in [-->][?:MerkleEdgeRow] {
        if row.component_id == purl { seeds.append(row.child_subtree_hash); }
    }
    if comp.subtree_hash != "" {
        found = False;
        for sh in seeds {
            if sh == comp.subtree_hash { found = True; }
        }
        if not found { seeds.append(comp.subtree_hash); }
    }
    claimed: dict[str, bool] = {};
    root_hashes: list[str] = [];
    for sh in seeds {
        w = root spawn UpStep(cur_hash=sh, claimed=claimed, root_hashes=[]);
        for rh in w.root_hashes {
            dup = False;
            for existing in root_hashes {
                if existing == rh { dup = True; }
            }
            if not dup { root_hashes.append(rh); }
        }
    }
    out: list[tuple[str, str, str]] = [];
    for s in [-->][?:SbomSource] {
        for rh in root_hashes {
            if s.root_hash == rh {
                out.append((s.asset_id, s.version, s.origin));
            }
        }
    }
    return sorted(out);
}
