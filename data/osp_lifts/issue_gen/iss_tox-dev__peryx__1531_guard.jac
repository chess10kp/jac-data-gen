node Blob { has cid: str; has digest: str; has ecosystem: str; }
node Repository { has cid: str; has name: str; has ecosystem: str; }
node StoreRoot { has cid: str; }

edge Contains {}
edge References {}

walker CollectLive {
    has claimed: dict[str, bool] = {};
    has digests: list[str] = [];
    can start with StoreRoot entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for repo in [here ->:Contains:->][?:Repository] {
            visit :0: [repo];
        }
    }
    can step_repo with Repository entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for b in [here ->:Contains:->][?:Blob] {
            visit :0: [b];
        }
    }
    can step_blob with Blob entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.digest not in self.digests {
            self.digests.append(here.digest);
        }
        for nxt in [here ->:References:->][?:Blob] {
            visit :0: [nxt];
        }
        print("visited " + here.digest);
    }
}

def make_store(cid: str) -> StoreRoot {
    nd = StoreRoot(cid=cid);
    root ++> nd;
    return nd;
}

def add_repository(store_root: StoreRoot, cid: str, name: str, ecosystem: str) -> Repository {
    repo = Repository(cid=cid, name=name, ecosystem=ecosystem);
    store_root +>:Contains:+> repo;
    return repo;
}

def add_blob(store_root: StoreRoot, repo: Repository, cid: str, digest: str, ecosystem: str) -> Blob {
    b = Blob(cid=cid, digest=digest, ecosystem=ecosystem);
    repo +>:Contains:+> b;
    return b;
}

def link_reference(src: Blob, dst: Blob) {
    src +>:References:+> dst;
}

def referenced_blob_digests(store_root: StoreRoot) -> list[str] {
    w = store_root spawn CollectLive(claimed={}, digests=[]);
    return sorted(w.digests);
}

def orphan_candidates(store_root: StoreRoot, live: list[str]) -> list[str] {
    all = referenced_blob_digests(store_root);
    out: list[str] = [];
    for d in all {
        if d not in live {
            out.append(d);
        }
    }
    return sorted(out);
}

with entry {
    demo = StoreRoot(cid="demo-root");
    root ++> demo;
    w = demo spawn CollectLive(claimed={}, digests=[]);
    print(w.digests);
}

test "diamond revisit across ecosystems adversarial order" {
    s = make_store("s-diamond");
    r_pypi = add_repository(s, "rpypi", "pypi-index", "pypi");
    r_oci = add_repository(s, "roci", "oci-index", "oci");
    top = add_blob(s, r_pypi, "b-top", "sha256:top", "pypi");
    left = add_blob(s, r_pypi, "b-left", "sha256:left", "pypi");
    right = add_blob(s, r_oci, "b-right", "sha256:right", "oci");
    bottom = add_blob(s, r_oci, "b-bottom", "sha256:bottom", "oci");
    link_reference(top, left);
    link_reference(top, right);
    link_reference(left, bottom);
    link_reference(right, bottom);
    live = referenced_blob_digests(s);
    assert(sorted(live) == sorted(["sha256:top", "sha256:left", "sha256:right", "sha256:bottom"]));
}

test "cycle and self-loop does not loop" {
    s = make_store("s-cycle");
    r = add_repository(s, "r1", "repo1", "pypi");
    a = add_blob(s, r, "ba", "sha256:a", "pypi");
    b = add_blob(s, r, "bb", "sha256:b", "pypi");
    c = add_blob(s, r, "bc", "sha256:c", "pypi");
    link_reference(a, b);
    link_reference(b, c);
    link_reference(c, a);
    link_reference(c, c);
    live = referenced_blob_digests(s);
    assert(sorted(live) == sorted(["sha256:a", "sha256:b", "sha256:c"]));
}

test "scan covers every stored ecosystem not just pypi" {
    s = make_store("s-eco");
    r_pypi = add_repository(s, "rp1", "pypi-repo", "pypi");
    r_oci = add_repository(s, "ro1", "oci-repo", "oci");
    p = add_blob(s, r_pypi, "bp1", "sha256:pypi-layer", "pypi");
    o1 = add_blob(s, r_oci, "bo1", "sha256:oci-manifest", "oci");
    o2 = add_blob(s, r_oci, "bo2", "sha256:oci-layer", "oci");
    link_reference(o1, o2);
    live = referenced_blob_digests(s);
    assert("sha256:oci-manifest" in live);
    assert("sha256:oci-layer" in live);
    assert("sha256:pypi-layer" in live);
    assert(len(live) == 3);
}

test "unknown live tolerance and empty store" {
    s = make_store("s-empty");
    assert(referenced_blob_digests(s) == []);
    r = add_repository(s, "r2", "pypi-repo2", "pypi");
    x = add_blob(s, r, "bx", "sha256:x", "pypi");
    y = add_blob(s, r, "by", "sha256:y", "pypi");
    assert(orphan_candidates(s, ["sha256:unknown", "sha256:x"]) == ["sha256:y"]);
    assert(orphan_candidates(s, []) == sorted(["sha256:x", "sha256:y"]));
    assert(referenced_blob_digests(s) == sorted(["sha256:x", "sha256:y"]));
}
