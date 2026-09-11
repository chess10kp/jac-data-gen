"""BootBlock/Gubbins#403 — backlog triage parent-issue chain for effective tier."""

node Issue {
    has iid: str;
    has tier: int;
}

edge ChildOf {}

obj BacklogRegistry {
    has issues: dict[str, Issue] = {};
}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Issue entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.found.append(here.iid);
        visit [<-:ChildOf:<-][?:Issue];
    }
}

def load_backlog(issues: list[tuple[str, int, str | None]]) -> BacklogRegistry {
    reg = BacklogRegistry();
    for (iid, tier, parent) in issues {
        if parent is not None and reg.issues.get(parent, None) is None {
            raise KeyError("unknown parent issue");
        }
        nd = Issue(iid=iid, tier=tier);
        root ++> nd;
        reg.issues[iid] = nd;
        if parent is not None {
            p = reg.issues.get(parent, None);
            if p is not None { nd +>:ChildOf:+> p; }
        }
    }
    return reg;
}

def _chain(reg: BacklogRegistry, issue_id: str) -> list[str] {
    nd = reg.issues.get(issue_id, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: Issue | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.iid in seen { break; }
        seen[cur.iid] = True;
        chain.append(cur.iid);
        parent: Issue | None = None;
        for p in [cur ->:ChildOf:->][?:Issue] {
            parent = p;
            break;
        }
        cur = parent;
    }
    return chain;
}

def ancestor_issues(reg: BacklogRegistry, issue_id: str) -> list[str] {
    chain = _chain(reg, issue_id);
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

def effective_tier(reg: BacklogRegistry, issue_id: str) -> int {
    chain = _chain(reg, issue_id);
    if len(chain) == 0 { return 99; }
    best = reg.issues[chain[0]].tier;
    for iid in chain {
        iss = reg.issues.get(iid, None);
        if iss is not None and iss.tier < best { best = iss.tier; }
    }
    return best;
}

def subtree_issues(reg: BacklogRegistry, `root: str) -> list[str] {
    nd = reg.issues.get(`root, None);
    if nd is None { return []; }
    w = nd spawn SubtreeWalk(claimed={}, found=[]);
    return sorted(w.found);
}

test "triage parent chain" {
    reg = load_backlog(
        [
            ("epic-sync", 2, None),
            ("502", 1, "epic-sync"),
            ("633", 2, "epic-sync"),
            ("sub-fix", 3, "633"),
        ],
    );
    assert ancestor_issues(reg, "sub-fix") == ["epic-sync", "633", "sub-fix"];
    assert effective_tier(reg, "sub-fix") == 2;
    assert subtree_issues(reg, "epic-sync") == [
        "502", "633", "epic-sync", "sub-fix"
    ];
}
