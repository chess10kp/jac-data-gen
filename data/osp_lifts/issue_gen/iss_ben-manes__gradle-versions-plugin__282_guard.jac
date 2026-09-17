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

test "recursive_closure_finds_transitive_updates" {
    a = add_module("app", "1.0", "1.0");
    b = add_module("fragment", "1.1.0-alpha02", "1.1.0-alpha03");
    c = add_module("preference", "1.1.0-alpha02", "1.1.0-alpha02");
    link("app", "preference");
    link("preference", "fragment");
    assert check_recursive("app") == ["fragment"];
}

test "diamond_revisit_no_duplicate_hits" {
    a = add_module("root", "1", "1");
    b = add_module("left", "1", "2");
    c = add_module("right", "1", "1");
    d = add_module("shared", "1", "9");
    link("root", "left");
    link("root", "right");
    link("left", "shared");
    link("right", "shared");
    hits = check_recursive("root");
    assert hits == ["shared", "left"] or hits == sorted(["left", "shared"]);
    assert len(hits) == 2;
}

test "cycle_terminates" {
    add_module("m1", "1", "2");
    add_module("m2", "1", "1");
    link("m1", "m2");
    link("m2", "m1");
    hits = check_recursive("m1");
    assert hits == ["m1"];
}

test "unknown_id_tolerant" {
    assert check_recursive("does-not-exist") == [];
}

test "leaf_module_no_deps" {
    add_module("lonely", "0.1", "0.2");
    assert check_recursive("lonely") == ["lonely"];
}

test "get_unknown_returns_none" {
    assert get("nope") == None;
}
