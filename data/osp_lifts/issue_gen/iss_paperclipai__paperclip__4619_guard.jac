"""Blocked-chain resolution lifted to OSP (paperclipai/paperclip#4619).

The issue table and its edge-list rescans die: "A blocks B" becomes a typed
``Blocks`` edge, chain resolution becomes ``ChainWalk`` hopping to the
first unclaimed successor, and the transitive query becomes a claiming
``ClosureWalk``. The cycle policy is the explicit claim-map -- the walker
stops at the first revisit instead of recursing until the process dies,
which is exactly the fix the issue asks for -- and unknown ids still fail
closed with KeyError.
"""

node Issue {
    has iid: str;
    has title: str;
    has state: str;  # "open" | "blocked" | "done"
}

edge Blocks: Issue --> Issue {}

glob board: dict[str, Issue] = {};


def add_issue(iid: str, title: str, state: str = "open") -> None {
    if iid in board {
        raise ValueError("duplicate");
    }
    if state not in ("open", "blocked", "done") {
        raise ValueError(state);
    }
    root ++> (n := Issue(iid=iid, title=title, state=state));
    board[iid] = n;
}


def add_blocks(blocker: str, blocked: str) -> None {
    for i in (blocker, blocked) {
        if i not in board {
            raise KeyError(i);
        }
    }
    board[blocker] +>:Blocks:+> board[blocked];
}


def blocked_by(iid: str) -> list[str] {
    out: set[str] = set();
    for n in [board[iid] ->:Blocks:->] {
        out.add(n.iid);
    }
    return sorted(out);
}


def blockers_of(iid: str) -> list[str] {
    ins: set[str] = set();
    for n in [board[iid] <-:Blocks:<-] {
        ins.add(n.iid);
    }
    return sorted(ins);
}


walker ChainWalk {
    """Follows the first successor until a dead end or a revisit."""
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    has hit_cycle: bool = False;

    can go with Issue entry {
        if here.iid in self.claimed {
            self.hit_cycle = True;
            return;  # cycle policy: stop at first repeat, never recurse
        }
        self.claimed[here.iid] = True;
        self.chain.append(here.iid);
        kid_ids = blocked_by(here.iid);
        kids: list[Issue] = [];
        for k in kid_ids {
            kids.append(board[k]);
        }
        if len(kids) == 0 {
            return;  # dead end of this branch
        }
        # source semantics: always follow the first successor; the claim-map
        # in the spawned sub-walker ends the chain on a revisit
        sub = ChainWalk(claimed=self.claimed);
        kids[0] spawn sub;
        self.chain.extend(sub.chain);
    }
}


walker ClosureWalk {
    """Claims every transitively blocked node once."""
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can go with Issue entry {
        if here.iid in self.claimed {
            return;
        }
        self.claimed[here.iid] = True;
        self.found.append(here.iid);
        for nb in [here ->:Blocks:->] {
            sub = ClosureWalk(claimed=self.claimed);
            nb spawn sub;
            self.found.extend(sub.found);
        }
    }
}


def first_blocked_chain(iid: str) -> list[str] {
    # chain from iid; stops at dead end or first revisit
    if iid not in board {
        raise KeyError(iid);
    }
    w = board[iid] spawn ChainWalk(claimed={});
    return w.chain;
}


def unblockable(iid: str) -> list[str] {
    # sorted open issues transitively reachable from iid
    if iid not in board {
        raise KeyError(iid);
    }
    w = board[iid] spawn ClosureWalk(claimed={});
    out: set[str] = set();
    for x in w.found {
        if board[x].state == "open" {
            out.add(x);
        }
    }
    return sorted(out);
}

test "chain and closure on a small board" {
    add_issue("1", "root cause");
    add_issue("2", "symptom A", "blocked");
    add_issue("3", "symptom B");
    add_issue("4", "crash", "blocked");
    add_blocks("1", "2");
    add_blocks("1", "3");
    add_blocks("2", "4");
    assert blocked_by("1") == ["2", "3"];
    assert blockers_of("4") == ["2"];
    assert first_blocked_chain("1") == ["1", "2", "4"];
    assert first_blocked_chain("3") == ["3"];
    assert unblockable("1") == ["1", "3"], unblockable("1");
}

test "circular dependency terminates at first revisit" {
    add_issue("cA", "a", "blocked");
    add_issue("cB", "b", "blocked");
    add_issue("cC", "c");
    add_blocks("cA", "cB");
    add_blocks("cB", "cA");  # the hostile cycle from the issue
    add_blocks("cA", "cC");
    assert first_blocked_chain("cA") == ["cA", "cB"];
    assert first_blocked_chain("cB") == ["cB", "cA"];
    assert unblockable("cA") == ["cC"];
}

test "deep chain stays linear" {
    prev = "";
    for i in range(30) {
        add_issue("n{}".format(i), str(i));
        if i > 0 {
            add_blocks(prev, "n{}".format(i));
        }
        prev = "n{}".format(i);
    }
    assert len(first_blocked_chain("n0")) == 30;
}

test "errors preserved" {
    add_issue("z1", "solo");
    try {
        add_blocks("z1", "ghost");
        assert False;
    } except KeyError {
        assert True;
    }
    try {
        add_issue("z1", "dup");
        assert False;
    } except ValueError {
        assert True;
    }
}
