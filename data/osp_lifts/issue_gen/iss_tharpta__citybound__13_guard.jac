node Review {
    has frozen_commit: str;
    has decision: str = "";
}
node Finding {
    has fid: str;
    has bucket: str = "unclassified";
    has title: str = "";
}
edge Owns {}
edge Depends {}

walker ReachProbe {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;
    can probe with Finding entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        print("cf " + here.fid);
        if here.fid == self.target {
            self.found = True;
        }
        kids: list[Finding] = [];
        for nxt in [here ->:Depends:->][?:Finding] {
            kids.append(nxt);
        }
        for k in kids {
            visit :0: [k];
        }
    }
}

walker LocateProbe {
    has target: str = "";
    has found: Finding | None = None;
    has claimed: dict[str, bool] = {};
    can locate_review with Review entry {
        if "r" in self.claimed { skip; }
        self.claimed["r"] = True;
        print("cf root " + here.frozen_commit);
        kids: list[Finding] = [];
        for f in [here ->:Owns:->][?:Finding] {
            kids.append(f);
        }
        for k in kids {
            if k.fid == self.target {
                self.found = k;
            }
            visit :0: [k];
        }
    }
    can locate_finding with Finding entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        print("cf " + here.fid);
        if here.fid == self.target {
            self.found = here;
        }
    }
}

def find_finding(review: Review, fid: str) -> Finding | None {
    # locate via direct edge scan without walker for simplicity and speed
    for f in [review ->:Owns:->][?:Finding] {
        if f.fid == fid {
            return f;
        }
    }
    return None;
}

def reachable_from(start: Finding, target: str) -> bool {
    if start.fid == target {
        return True;
    }
    w = start spawn ReachProbe(target=target, claimed={});
    return w.found;
}

def create_review(frozen_commit: str) -> Review {
    rv = Review(frozen_commit=frozen_commit);
    root ++> rv;
    return rv;
}

def add_finding(review: Review, fid: str, title: str) -> bool {
    if find_finding(review, fid) != None {
        return False;
    }
    nd = Finding(fid=fid, title=title);
    review +>:Owns:+> nd;
    return True;
}

def classify_finding(review: Review, fid: str, bucket: str) -> bool {
    nd = find_finding(review, fid);
    if nd == None {
        return False;
    }
    # buckets: exit_blocker, accepted_risk, backlog, unclassified
    nd.bucket = bucket;
    return True;
}

def add_dependency(review: Review, src: str, dst: str) -> bool {
    s = find_finding(review, src);
    d = find_finding(review, dst);
    if s == None { return False; }
    if d == None { return False; }
    s +>:Depends:+> d;
    return True;
}

def is_reachable(review: Review, src: str, dst: str) -> bool {
    s = find_finding(review, src);
    d = find_finding(review, dst);
    if s == None { return False; }
    if d == None { return False; }
    if src == dst { return True; }
    return reachable_from(s, dst);
}

def reachable(review: Review, src: str, dst: str) -> bool {
    return is_reachable(review, src, dst);
}

def can_reach(review: Review, src: str, dst: str) -> bool {
    return is_reachable(review, src, dst);
}

def has_cycle(review: Review) -> bool {
    findings: list[Finding] = [];
    for f in [review ->:Owns:->][?:Finding] {
        findings.append(f);
    }
    for f in findings {
        succs: list[Finding] = [];
        for nxt in [f ->:Depends:->][?:Finding] {
            succs.append(nxt);
        }
        for s in succs {
            if reachable_from(s, f.fid) {
                return True;
            }
        }
    }
    return False;
}

def detect_cycle(review: Review) -> bool {
    return has_cycle(review);
}

def decide(review: Review) -> str {
    has_blocker: bool = False;
    has_risk: bool = False;
    for f in [review ->:Owns:->][?:Finding] {
        if f.bucket == "exit_blocker" {
            has_blocker = True;
        }
        if f.bucket == "accepted_risk" {
            has_risk = True;
        }
    }
    if has_blocker {
        review.decision = "NO-GO";
        return "NO-GO";
    }
    if has_risk {
        review.decision = "CONDITIONAL GO";
        return "CONDITIONAL GO";
    }
    review.decision = "GO";
    return "GO";
}

test "diamond_revisit_path_reach" {
    rv = create_review("3825e90801454ae3c35fcb4753a8262d7dfcabf8");
    assert(add_finding(rv, "A", "a") == True);
    assert(add_finding(rv, "B", "b") == True);
    assert(add_finding(rv, "C", "c") == True);
    assert(add_finding(rv, "D", "d") == True);
    # adversarial insertion order: A->C first, then A->B so revisit fires early
    assert(add_dependency(rv, "A", "C") == True);
    assert(add_dependency(rv, "A", "B") == True);
    assert(add_dependency(rv, "C", "D") == True);
    assert(add_dependency(rv, "B", "D") == True);
    assert(is_reachable(rv, "A", "D") == True);
    assert(is_reachable(rv, "B", "C") == False);
    assert(has_cycle(rv) == False);
}

test "blocker_classification_decides_no_go" {
    rv = create_review("3825e90801454ae3c35fcb4753a8262d7dfcabf8");
    assert(add_finding(rv, "53", "install exposure") == True);
    assert(add_finding(rv, "8", "disappearing road") == True);
    assert(classify_finding(rv, "53", "exit_blocker") == True);
    assert(classify_finding(rv, "8", "backlog") == True);
    assert(decide(rv) == "NO-GO");
    assert(has_cycle(rv) == False);
}

test "conditional_go_and_unknown_tolerance" {
    rv = create_review("3825e90801454ae3c35fcb4753a8262d7dfcabf8");
    assert(add_finding(rv, "5", "runtime evidence") == True);
    assert(add_finding(rv, "54", "audit") == True);
    assert(classify_finding(rv, "54", "accepted_risk") == True);
    # unknown ids must not raise
    assert(classify_finding(rv, "999", "exit_blocker") == False);
    assert(is_reachable(rv, "999", "5") == False);
    assert(add_dependency(rv, "5", "999") == False);
    assert(decide(rv) == "CONDITIONAL GO");
}

test "cycle_detection_blocks_traversal" {
    rv = create_review("3825e90801454ae3c35fcb4753a8262d7dfcabf8");
    assert(add_finding(rv, "1", "n1") == True);
    assert(add_finding(rv, "2", "n2") == True);
    assert(add_finding(rv, "3", "n3") == True);
    assert(add_dependency(rv, "1", "2") == True);
    assert(add_dependency(rv, "2", "3") == True);
    assert(has_cycle(rv) == False);
    assert(add_dependency(rv, "3", "1") == True);
    assert(has_cycle(rv) == True);
    assert(is_reachable(rv, "1", "3") == True);
    assert(is_reachable(rv, "3", "2") == True);
}

test "go_when_no_blockers" {
    rv = create_review("3825e90801454ae3c35fcb4753a8262d7dfcabf8");
    assert(add_finding(rv, "54", "x") == True);
    assert(add_finding(rv, "55", "y") == True);
    assert(classify_finding(rv, "54", "backlog") == True);
    assert(classify_finding(rv, "55", "backlog") == True);
    assert(decide(rv) == "GO");
}
