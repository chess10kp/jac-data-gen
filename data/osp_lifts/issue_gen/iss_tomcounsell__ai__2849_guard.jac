# iss_tomcounsell__ai__2849.jac — SDLC issue stale via long-lived AgentSession
# Python source: tomcounsell/ai#2849 synthetic hand-rolled machinery lifted to OSP

node AgentSession { has sid: str; has issue_url: str; has issue_num: int = 0; }
node Issue { has num: int; has url: str; }
node Stage { has sid: str; }
node Package { has pname: str; }

edge Depends {}
edge References {}
edge Lineage {}
edge SessionLink {}

walker StageReachWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can reach with Stage entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.found.append(here.sid);
        print(here.sid);
        kids: list[Stage] = [];
        for ch in [here ->:Depends:->][?:Stage] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker PackageLineageWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Package entry {
        if here.pname in self.claimed { skip; }
        self.claimed[here.pname] = True;
        self.found.append(here.pname);
        print(here.pname);
        kids: list[Package] = [];
        for ch in [here ->:Lineage:->][?:Package] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker StageIssueWalker {
    has claimed: dict[str, bool] = {};
    has found: list[int] = [];
    can step_issue with Stage entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        print(here.sid);
        for iss in [here ->:References:->][?:Issue] {
            self.found.append(iss.num);
        }
        kids: list[Stage] = [];
        for ch in [here ->:Depends:->][?:Stage] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def get_reachable_stages(start: Stage) -> list[str] {
    # collect walk via claim-map then return outside walk
    w = start spawn StageReachWalker(claimed={}, found=[]);
    return w.found;
}

def get_lineage_chain(start: Package) -> list[str] {
    w = start spawn PackageLineageWalker(claimed={}, found=[]);
    return w.found;
}

def get_referenced_issue_numbers(start: Stage) -> list[int] {
    w = start spawn StageIssueWalker(claimed={}, found=[]);
    return w.found;
}

def is_session_stale(sess: AgentSession, routed_num: int) -> bool {
    # stale if session still pins old issue_num vs current routed task
    if sess.issue_num == 0 { return False; }
    return sess.issue_num != routed_num;
}

def extract_issue_number(url: str) -> int {
    # helper for completeness - parses trailing digits
    n: int = 0;
    found: bool = False;
    # scan from end backwards to collect trailing digits then parse forward
    digits: list[str] = [];
    # collect trailing digits reversed
    # we walk backwards via index
    idx: int = len(url) - 1;
    while idx >= 0 {
        ch: str = url[idx];
        if ch >= "0" and ch <= "9" {
            digits.append(ch);
            found = True;
        } else {
            if found { break; }
        }
        idx = idx - 1;
        if idx < 0 { break; }
    }
    if found == False { return -1; }
    # digits is reversed trailing number; reverse and compute
    val: int = 0;
    mult: int = 1;
    for d in digits {
        # d is str digit char
        code: int = 0;
        if d == "0" { code = 0; } elif d == "1" { code = 1; } elif d == "2" { code = 2; } elif d == "3" { code = 3; } elif d == "4" { code = 4; } elif d == "5" { code = 5; } elif d == "6" { code = 6; } elif d == "7" { code = 7; } elif d == "8" { code = 8; } else { code = 9; }
        val = val + code * mult;
        mult = mult * 10;
    }
    return val;
}

with entry {
    demo = Stage(sid="demo_root");
    root ++> demo;
    w = demo spawn StageReachWalker(claimed={}, found=[]);
    print("demo done");
}

test "diamond_reachable_stages_adversarial_order" {
    a = Stage(sid="a"); b = Stage(sid="b"); c = Stage(sid="c"); d = Stage(sid="d");
    root ++> a; root ++> b; root ++> c; root ++> d;
    a +>:Depends:+> b;
    a +>:Depends:+> c;
    c +>:Depends:+> d;
    b +>:Depends:+> d;
    got = get_reachable_stages(a);
    assert(sorted(got) == sorted(["a", "b", "c", "d"]));;
}

test "cycle_does_not_loop" {
    x = Stage(sid="x"); y = Stage(sid="y");
    root ++> x; root ++> y;
    x +>:Depends:+> y;
    y +>:Depends:+> x;
    got = get_reachable_stages(x);
    assert(sorted(got) == sorted(["x", "y"]));;
}

test "unknown_isolated_returns_self" {
    iso = Stage(sid="iso");
    root ++> iso;
    got = get_reachable_stages(iso);
    assert(got == ["iso"]);;
}

test "stale_session_detection" {
    sess = AgentSession(sid="s1", issue_url="https://github.com/tomcounsell/ai/issues/2734", issue_num=2734);
    root ++> sess;
    assert(is_session_stale(sess, 2734) == False);;
    assert(is_session_stale(sess, 2636) == True);;
    sess2 = AgentSession(sid="s2", issue_url="", issue_num=0);
    root ++> sess2;
    assert(is_session_stale(sess2, 99) == False);;
}

test "referenced_issues_via_dag" {
    s1 = Stage(sid="s1"); s2 = Stage(sid="s2");
    iss1 = Issue(num=2734, url="https://github.com/tomcounsell/ai/issues/2734");
    iss2 = Issue(num=2636, url="https://github.com/tomcounsell/ai/issues/2636");
    root ++> s1; root ++> s2; root ++> iss1; root ++> iss2;
    s1 +>:Depends:+> s2;
    s1 +>:References:+> iss1;
    s2 +>:References:+> iss2;
    got = get_referenced_issue_numbers(s1);
    assert(sorted(got) == sorted([2734, 2636]));;
}

test "lineage_chain_with_diamond" {
    p_a = Package(pname="a"); p_b = Package(pname="b"); p_c = Package(pname="c"); p_d = Package(pname="d");
    root ++> p_a; root ++> p_b; root ++> p_c; root ++> p_d;
    p_a +>:Lineage:+> p_b;
    p_a +>:Lineage:+> p_c;
    p_b +>:Lineage:+> p_d;
    p_c +>:Lineage:+> p_d;
    got = get_lineage_chain(p_a);
    assert(sorted(got) == sorted(["a", "b", "c", "d"]));;
}
