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
