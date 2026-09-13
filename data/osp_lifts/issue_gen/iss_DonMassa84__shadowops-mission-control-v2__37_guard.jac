node Branch {
    has bid: str;
    has agent: int = 0;
    has role: str = "";
    has status: str = "pending";
}

node Board {
    has board_id: str;
}

edge DependsOn {}
edge Contains {}

walker TransitiveDepsWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];
    has started: bool = False;

    can step with Branch entry {
        if here.bid in self.claimed { skip; }
        self.claimed[here.bid] = True;
        if self.started {
            self.result.append(here.bid);
        }
        self.started = True;
        print(here.bid);
        for dep in [here ->:DependsOn:->][?:Branch] {
            visit :0: [dep];
        }
    }
}

walker DemoWalker {
    has msg: str = "demo";
    can demo with entry {
        print(self.msg);
        disengage;
    }
}

def create_board(board_id: str) -> Board {
    b = Board(board_id=board_id);
    return b;
}

def find_branch(board: Board, bid: str) -> Branch | None {
    for b in [board ->:Contains:->][?:Branch] {
        if b.bid == bid {
            return b;
        }
    }
    return None;
}

def add_branch(board: Board, bid: str, agent: int, role: str, status: str) -> Branch {
    nd = Branch(bid=bid, agent=agent, role=role, status=status);
    board +>:Contains:+> nd;
    return nd;
}

def add_dependency(board: Board, from_bid: str, to_bid: str) -> bool {
    src = find_branch(board, from_bid);
    dst = find_branch(board, to_bid);
    if src is None {
        return False;
    }
    if dst is None {
        return False;
    }
    src +>:DependsOn:+> dst;
    return True;
}

def get_transitive_dependencies(board: Board, bid: str) -> list[str] {
    tgt = find_branch(board, bid);
    if tgt is None {
        return [];
    }
    w = tgt spawn TransitiveDepsWalker(claimed={}, result=[], started=False);
    return sorted(w.result);
}

def get_transitive_dependents(board: Board, bid: str) -> list[str] {
    tgt = find_branch(board, bid);
    if tgt is None {
        return [];
    }
    out: list[str] = [];
    for b in [board ->:Contains:->][?:Branch] {
        if b.bid == bid {
            continue;
        }
        deps = get_transitive_dependencies(board, b.bid);
        for d in deps {
            if d == bid {
                out.append(b.bid);
                break;
            }
        }
    }
    return sorted(out);
}

def get_blocked(board: Board) -> list[str] {
    out: list[str] = [];
    for b in [board ->:Contains:->][?:Branch] {
        if b.status == "PASS" {
            continue;
        }
        for dep in [b ->:DependsOn:->][?:Branch] {
            if dep.status != "PASS" {
                out.append(b.bid);
                break;
            }
        }
    }
    return sorted(out);
}

def get_ready_for_certification(board: Board) -> list[str] {
    out: list[str] = [];
    for b in [board ->:Contains:->][?:Branch] {
        if b.status == "PASS" {
            continue;
        }
        blocked: bool = False;
        for dep in [b ->:DependsOn:->][?:Branch] {
            if dep.status != "PASS" {
                blocked = True;
                break;
            }
        }
        if not blocked {
            out.append(b.bid);
        }
    }
    return sorted(out);
}

def is_rc_ready(board: Board) -> bool {
    for b in [board ->:Contains:->][?:Branch] {
        if b.status != "PASS" {
            return False;
        }
    }
    return True;
}

with entry {
    root spawn DemoWalker(msg="ShadowOps Review Board 37 active");
}

test "diamond transitive deps adversarial order" {
    board = create_board("board-diamond");
    d = add_branch(board, "D", 0, "base", "PASS");
    b = add_branch(board, "B", 0, "branch", "pending");
    c = add_branch(board, "C", 0, "branch", "pending");
    a = add_branch(board, "A", 0, "branch", "pending");
    add_dependency(board, "A", "C");
    add_dependency(board, "A", "B");
    add_dependency(board, "B", "D");
    add_dependency(board, "C", "D");
    deps = get_transitive_dependencies(board, "A");
    assert (deps == ["B", "C", "D"]);
    deps2 = get_transitive_dependencies(board, "B");
    assert (deps2 == ["D"]);
    dependents_d = get_transitive_dependents(board, "D");
    assert (dependents_d == ["A", "B", "C"]);
}

test "unknown id tolerance" {
    board = create_board("board-unknown");
    add_branch(board, "X", 1, "review", "PASS");
    assert (get_transitive_dependencies(board, "NOPE") == []);
    assert (get_transitive_dependents(board, "NOPE") == []);
    assert (add_dependency(board, "X", "MISSING") == False);
    assert (add_dependency(board, "MISSING", "X") == False);
    assert (get_transitive_dependencies(board, "X") == []);
}

test "blocked and ready certification" {
    board = create_board("board-cert");
    add_branch(board, "auto/opencode-review", 2, "General Code Review", "PASS");
    add_branch(board, "auto/opencode-cert-audit", 3, "Credo Gate", "PASS");
    add_branch(board, "auto/opencode-ux-review", 4, "UI A11y", "PASS");
    add_branch(board, "auto/opencode-security-audit", 5, "Security", "pending");
    add_branch(board, "auto/opencode-performance-review", 6, "Perf", "PASS");
    add_branch(board, "auto/opencode-docs-audit", 7, "Docs", "pending");
    add_branch(board, "auto/opencode-integration-test", 8, "Integration", "pending");
    add_dependency(board, "auto/opencode-docs-audit", "auto/opencode-cert-audit");
    add_dependency(board, "auto/opencode-docs-audit", "auto/opencode-ux-review");
    add_dependency(board, "auto/opencode-docs-audit", "auto/opencode-security-audit");
    add_dependency(board, "auto/opencode-docs-audit", "auto/opencode-performance-review");
    add_dependency(board, "auto/opencode-integration-test", "auto/opencode-cert-audit");
    add_dependency(board, "auto/opencode-integration-test", "auto/opencode-performance-review");
    blocked = get_blocked(board);
    assert (blocked == ["auto/opencode-docs-audit"]);
    ready = get_ready_for_certification(board);
    assert (ready == ["auto/opencode-integration-test", "auto/opencode-security-audit"]);
    assert (is_rc_ready(board) == False);
}

test "rc ready and cycle closure" {
    board = create_board("board-rc");
    add_branch(board, "A", 1, "r", "PASS");
    add_branch(board, "B", 2, "r", "PASS");
    add_branch(board, "C", 3, "r", "PASS");
    assert (is_rc_ready(board) == True);
    add_branch(board, "D", 4, "r", "pending");
    assert (is_rc_ready(board) == False);
    add_dependency(board, "A", "B");
    add_dependency(board, "B", "C");
    add_dependency(board, "C", "A");
    deps_a = get_transitive_dependencies(board, "A");
    assert (sorted(deps_a) == ["B", "C"]);
    deps_b = get_transitive_dependencies(board, "B");
    assert (sorted(deps_b) == ["A", "C"]);
}
