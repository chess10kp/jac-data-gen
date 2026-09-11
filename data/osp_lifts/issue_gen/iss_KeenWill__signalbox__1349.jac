node Frontier {
    has fid: str;
    has summary: str = "";
}

node Member {
    has mid: str;
}

node Compaction {
    has cid: str;
    has result_summary: str = "";
}

edge Prefix {}
edge HasMember {}

walker MemberSearch {
    has claimed: dict[str, bool] = {};
    has wanted: str = "";
    has found: bool = False;
    has found_depth: int = -1;
    has depths: dict[str, int] = {};
    can search with Frontier entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        cur: int = 0;
        if here.fid in self.depths {
            cur = self.depths[here.fid];
        }
        for m in [here ->:HasMember:->][?:Member] {
            if m.mid == self.wanted {
                self.found = True;
                self.found_depth = cur;
            }
        }
        print("search " + here.fid);
        if self.found {
            disengage;
        }
        kids: list[Frontier] = [here ->:Prefix:->][?:Frontier];
        for k in kids {
            if k.fid not in self.depths {
                self.depths[k.fid] = cur + 1;
            }
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker PrefixClosureWalker {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;
    can traverse with Frontier entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        if here.fid == self.target {
            self.found = True;
        }
        print("closure " + here.fid);
        kids: list[Frontier] = [here ->:Prefix:->][?:Frontier];
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker DemoRootWalker {
    has dummy: bool = False;
    can run with Frontier entry {
        print("demo root walker");
        disengage;
    }
}

def make_frontier(fid: str) -> Frontier {
    nd = Frontier(fid=fid, summary="");
    root ++> nd;
    return nd;
}

def make_frontier_with_summary(fid: str, summary: str) -> Frontier {
    nd = Frontier(fid=fid, summary=summary);
    root ++> nd;
    return nd;
}

def link_prefix(frontier: Frontier, prefix: Frontier) {
    frontier +>:Prefix:+> prefix;
}

def add_member(frontier: Frontier, mid: str) {
    m = Member(mid=mid);
    root ++> m;
    frontier +>:HasMember:+> m;
}

def make_compaction(cid: str, summary: str) -> Compaction {
    c = Compaction(cid=cid, result_summary=summary);
    root ++> c;
    return c;
}

def context_frontier_member_position(start: Frontier, wanted: str) -> int {
    init: dict[str, int] = {};
    init[start.fid] = 0;
    w = start spawn MemberSearch(claimed={}, wanted=wanted, found=False, found_depth=-1, depths=init);
    if w.found {
        return w.found_depth;
    }
    return -1;
}

def context_frontier_preserves_prefix(start: Frontier, target_fid: str) -> bool {
    w = start spawn PrefixClosureWalker(claimed={}, target=target_fid, found=False);
    return w.found;
}

def require_context_compaction_exact_evidence(comp: Compaction, expected: str) -> bool {
    if comp.result_summary == "" {
        return False;
    }
    if expected == "" {
        return False;
    }
    return comp.result_summary == expected;
}

with entry {
    a = Frontier(fid="entry_a", summary="s");
    b = Frontier(fid="entry_b", summary="s2");
    root ++> a;
    root ++> b;
    a +>:Prefix:+> b;
    add_member(b, "demo_member");
    init: dict[str, int] = {};
    init[a.fid] = 0;
    w = a spawn MemberSearch(claimed={}, wanted="demo_member", found=False, found_depth=-1, depths=init);
    print("entry demo member search done");
    w2 = a spawn PrefixClosureWalker(claimed={}, target="entry_b", found=False);
    print("entry demo closure done");
    root spawn DemoRootWalker(dummy=False);
    print("demo entry done");
}
