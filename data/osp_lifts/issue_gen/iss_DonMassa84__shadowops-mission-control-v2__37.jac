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
