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
