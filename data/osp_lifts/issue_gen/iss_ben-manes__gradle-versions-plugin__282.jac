# ben-manes/gradle-versions-plugin#282 — recursive dependency update check
node Module {
    has cid: str;
    has cur: str;
    has latest: str;
    has outdated: bool = False;
}

edge Depends {}

glob registry: dict[str, Module] = {};

def add_module(cid: str, cur: str, latest: str) -> Module {
    m = Module(cid=cid, cur=cur, latest=latest);
    registry[cid] = m;
    return m;
}

def link(src_cid: str, dst_cid: str) -> None {
    a = registry[src_cid];
    b = registry[dst_cid];
    a +>:Depends:+> b;
}

def get(cid: str) -> Module | None {
    return registry[cid];
}

walker UpdateWalker {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Module entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cur != here.latest {
            here.outdated = True;
            self.hits.append(here.cid);
        }
        kids: list[Module] = [];
        for ch in [here ->:Depends:->][?:Module] {
            kids.append(ch);
        }
        kids = sorted(kids, key=lambda n: n.cid);
        if len(kids) > 0 {
            visit kids;
        } else {
            disengage;
        }
    }
}

def check_recursive(root_cid: str) -> list[str] {
    if root_cid not in registry {
        return [];
    }
    start: Module = registry[root_cid];
    wk = start spawn UpdateWalker(claimed={});
    return sorted(wk.hits);
}
