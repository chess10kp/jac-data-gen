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

test "member position diamond adversarial" {
    a = make_frontier("da");
    b = make_frontier("db");
    c = make_frontier("dc");
    d = make_frontier("dd");
    add_member(d, "wanted");
    link_prefix(a, b);
    link_prefix(a, c);
    link_prefix(b, d);
    link_prefix(c, d);
    pos = context_frontier_member_position(a, "wanted");
    assert(pos == 2);
    pos2 = context_frontier_member_position(a, "missing");
    assert(pos2 == -1);
    # reverse insertion order diamond must still find via closure
    a2 = make_frontier("da2");
    b2 = make_frontier("db2");
    c2 = make_frontier("dc2");
    d2 = make_frontier("dd2");
    add_member(d2, "want2");
    link_prefix(a2, c2);
    link_prefix(a2, b2);
    link_prefix(c2, d2);
    link_prefix(b2, d2);
    assert(context_frontier_member_position(a2, "want2") == 2);
    assert(context_frontier_preserves_prefix(a2, "dd2") == True);
}

test "prefix cycle guarded" {
    x = make_frontier("cx");
    y = make_frontier("cy");
    z = make_frontier("cz");
    link_prefix(x, y);
    link_prefix(y, z);
    link_prefix(z, x);
    add_member(y, "m1");
    assert(context_frontier_member_position(x, "m1") == 1);
    assert(context_frontier_member_position(x, "ghost") == -1);
    assert(context_frontier_preserves_prefix(x, "cz") == True);
    assert(context_frontier_preserves_prefix(x, "ghost") == False);
    assert(context_frontier_preserves_prefix(z, "cx") == True);
    s = make_frontier("self1");
    link_prefix(s, s);
    add_member(s, "self_m");
    assert(context_frontier_member_position(s, "self_m") == 0);
    assert(context_frontier_preserves_prefix(s, "self1") == True);
    assert(context_frontier_member_position(s, "nope") == -1);
}

test "compaction evidence null closed" {
    c1 = make_compaction("c1", "summ1");
    assert(require_context_compaction_exact_evidence(c1, "summ1") == True);
    assert(require_context_compaction_exact_evidence(c1, "other") == False);
    c_null = make_compaction("c2", "");
    assert(require_context_compaction_exact_evidence(c_null, "summ1") == False);
    assert(require_context_compaction_exact_evidence(c_null, "") == False);
    c_ok = make_compaction("c3", "ok");
    assert(require_context_compaction_exact_evidence(c_ok, "") == False);
    c_empty_match = make_compaction("c4", "");
    assert(require_context_compaction_exact_evidence(c_empty_match, "") == False);
}

test "unknown ids tolerance and preserves prefix diamond revisit" {
    a = make_frontier("pa");
    b = make_frontier("pb");
    c = make_frontier("pc");
    d = make_frontier("pd");
    link_prefix(a, b);
    link_prefix(a, c);
    link_prefix(b, d);
    link_prefix(c, d);
    assert(context_frontier_preserves_prefix(a, "pd") == True);
    assert(context_frontier_preserves_prefix(b, "pa") == False);
    assert(context_frontier_preserves_prefix(a, "ghost") == False);
    assert(context_frontier_member_position(a, "unknown_xyz") == -1);
    lone = make_frontier("lone");
    assert(context_frontier_preserves_prefix(lone, "lone") == True);
    assert(context_frontier_preserves_prefix(lone, "other") == False);
    assert(context_frontier_member_position(lone, "any") == -1);
}
