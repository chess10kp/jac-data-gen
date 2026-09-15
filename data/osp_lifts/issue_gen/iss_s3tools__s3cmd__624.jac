"""s3tools/s3cmd#624 — stream recursive prefix listings page-by-page."""

node ListingRoot {
    has rid: str;
}

node PrefixNode {
    has pid: str;
    has name: str;
}

node FileNode {
    has fid: str;
    has key: str;
    has size: int = 0;
}

edge Child {}

walker PageWalker {
    has claimed: dict[str, bool] = {};
    has page_size: int = 10;
    has pages: list[list[str]] = [];
    has cur_page: list[str] = [];

    can step with PrefixNode entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        files: list[FileNode] = [here ->:Child:->][?:FileNode];
        keys: list[str] = [];
        for f in files {
            keys.append(f.key);
        }
        keys = sorted(keys);
        for k in keys {
            self.cur_page.append(k);
            if len(self.cur_page) >= self.page_size {
                flushed: list[str] = [];
                for x in self.cur_page {
                    flushed.append(x);
                }
                self.pages.append(flushed);
                self.cur_page = [];
            }
        }
        subs: list[PrefixNode] = [here ->:Child:->][?:PrefixNode];
        sub_ids: list[str] = [];
        sub_map: dict[str, PrefixNode] = {};
        for s in subs {
            sub_ids.append(s.pid);
            sub_map[s.pid] = s;
        }
        sub_ids = sorted(sub_ids);
        nxt: list[PrefixNode] = [];
        for sid in sub_ids {
            nxt.append(sub_map[sid]);
        }
        print("page-walk", here.pid, len(self.pages));
        visit :0: nxt else {
            disengage;
        }
    }
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has all_keys: list[str] = [];

    can step with PrefixNode entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        for f in [here ->:Child:->][?:FileNode] {
            self.all_keys.append(f.key);
        }
        subs: list[PrefixNode] = [here ->:Child:->][?:PrefixNode];
        sub_ids: list[str] = [];
        sub_map: dict[str, PrefixNode] = {};
        for s in subs {
            sub_ids.append(s.pid);
            sub_map[s.pid] = s;
        }
        sub_ids = sorted(sub_ids);
        nxt: list[PrefixNode] = [];
        for sid in sub_ids {
            nxt.append(sub_map[sid]);
        }
        print("collect", here.pid, len(self.all_keys));
        visit :0: nxt else {
            disengage;
        }
    }
}

walker FindWalker {
    has target: str;
    has hit: PrefixNode | None = None;
    has claimed: dict[str, bool] = {};

    can step_root with ListingRoot entry {
        kids: list[PrefixNode] = [here ->:Child:->][?:PrefixNode];
        for p in kids {
            if p.pid == self.target {
                self.hit = p;
                print("find-hit", self.target);
                disengage;
            }
        }
        print("find-root", self.target);
        visit :0: kids else {
            disengage;
        }
    }

    can step with PrefixNode entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        if here.pid == self.target {
            self.hit = here;
            print("find-hit", self.target);
            disengage;
        }
        subs: list[PrefixNode] = [here ->:Child:->][?:PrefixNode];
        sub_ids: list[str] = [];
        sub_map: dict[str, PrefixNode] = {};
        for s in subs {
            sub_ids.append(s.pid);
            sub_map[s.pid] = s;
        }
        sub_ids = sorted(sub_ids);
        nxt: list[PrefixNode] = [];
        for sid in sub_ids {
            nxt.append(sub_map[sid]);
        }
        print("find-step", here.pid);
        visit :0: nxt else {
            disengage;
        }
    }
}

def make_root(rid: str) -> ListingRoot {
    gr = ListingRoot(rid=rid);
    root ++> gr;
    return gr;
}

def add_prefix(parent: PrefixNode | ListingRoot, pid: str, name: str) -> PrefixNode {
    p = PrefixNode(pid=pid, name=name);
    parent +>:Child:+> p;
    return p;
}

def add_object(parent: PrefixNode, oid: str, key: str, size: int) -> FileNode {
    o = FileNode(fid=oid, key=key, size=size);
    parent +>:Child:+> o;
    return o;
}

def find_prefix(graph_root: ListingRoot, pid: str) -> PrefixNode | None {
    w = graph_root spawn FindWalker(target=pid, hit=None, claimed={});
    return w.hit;
}

def list_recursive_buffered(root_prefix: PrefixNode) -> list[str] {
    w = root_prefix spawn CollectWalker(claimed={}, all_keys=[]);
    return sorted(w.all_keys);
}

def list_recursive_pages(root_prefix: PrefixNode, page_size: int) -> list[list[str]] {
    w = root_prefix spawn PageWalker(claimed={}, page_size=page_size, pages=[], cur_page=[]);
    if len(w.cur_page) > 0 {
        tail: list[str] = [];
        for x in w.cur_page {
            tail.append(x);
        }
        w.pages.append(tail);
    }
    return w.pages;
}

def list_recursive_pages_by_id(graph_root: ListingRoot, pid: str, page_size: int) -> list[list[str]] {
    hit = find_prefix(graph_root, pid);
    if hit is None {
        return [];
    }
    return list_recursive_pages(hit, page_size);
}

with entry {
    gr = make_root("demo");
    p = add_prefix(gr, "bucket", "bucket");
    add_object(p, "f1", "bucket/x.txt", 4);
    add_object(p, "f2", "bucket/y.txt", 8);
    pages = list_recursive_pages(p, 1);
    print("demo-pages", pages);
}
