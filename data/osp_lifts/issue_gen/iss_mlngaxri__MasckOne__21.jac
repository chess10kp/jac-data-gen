node Cell {
    has cid: str;
    has capability: str;
    has release_state: str;
}
node QRoot {
    has verified_sha: str;
}
edge Owns {}
edge Depends {}

walker CollectDeps {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Cell entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        kids: list[Cell] = [here ->:Depends:->][?:Cell];
        to_visit: list[Cell] = [];
        for k in kids {
            if k.cid not in self.claimed {
                exists: bool = False;
                for f in self.found {
                    if f == k.cid { exists = True; }
                }
                if not exists {
                    self.found.append(k.cid);
                }
            }
            to_visit.append(k);
        }
        if len(to_visit) > 0 {
            visit :0: to_visit;
        } else {
            disengage;
        }
        print(self.found);
    }
}
walker EntryWalk {
    has claimed: dict[str, bool] = {};
    can go with QRoot entry {
        print(here.verified_sha);
        disengage;
    }
}

def is_valid_sha(s: str) -> bool {
    # format only check 40 hex chars
    if len(s) != 40 { return False; }
    for ch in s {
        ok: bool = False;
        for h in "0123456789abcdefABCDEF" {
            if ch == h { ok = True; }
        }
        if not ok { return False; }
    }
    return True;
}
def new_queue(verified_sha: str) -> QRoot {
    q: QRoot = QRoot(verified_sha=verified_sha);
    return q;
}
def find_cell(root_node: QRoot, cid: str) -> Cell | None {
    cells: list[Cell] = [root_node ->:Owns:->][?:Cell];
    for c in cells {
        if c.cid == cid { return c; }
    }
    return None;
}
def register_cell(root_node: QRoot, cid: str, capability: str, release_state: str) -> Cell {
    nd: Cell = Cell(cid=cid, capability=capability, release_state=release_state);
    root_node +>:Owns:+> nd;
    return nd;
}
def add_depends(root_node: QRoot, from_cid: str, to_cid: str) -> bool {
    src: Cell | None = find_cell(root_node, from_cid);
    dst: Cell | None = find_cell(root_node, to_cid);
    if src is None { return False; }
    if dst is None { return False; }
    if src is not None {
        if dst is not None {
            src +>:Depends:+> dst;
            return True;
        }
    }
    return False;
}
def get_transitive_deps(root_node: QRoot, cid: str) -> list[str] {
    start: Cell | None = find_cell(root_node, cid);
    if start is None { return []; }
    if start is not None {
        w: CollectDeps = start spawn CollectDeps(claimed={}, found=[]);
        res: list[str] = w.found;
        return sorted(res);
    }
    return [];
}
def validate_provenance(root_node: QRoot, claimed_sha: str) -> bool {
    if not is_valid_sha(claimed_sha) { return False; }
    if claimed_sha == root_node.verified_sha { return True; }
    return False;
}
def is_ready_to_start(root_node: QRoot, cid: str) -> bool {
    deps: list[str] = get_transitive_deps(root_node, cid);
    for d in deps {
        c: Cell | None = find_cell(root_node, d);
        if c is not None {
            if c.release_state == "WAIT" { return False; }
            if c.release_state == "HOLD" { return False; }
        }
    }
    return True;
}
with entry {
    r: QRoot = QRoot(verified_sha="cdcc6c5d7041a4b0d7594a7c8aa4fc58a8346207");
    root ++> r;
    c: Cell = Cell(cid="demo", capability="actuator", release_state="READY");
    r +>:Owns:+> c;
    w = c spawn CollectDeps(claimed={}, found=[]);
    print(w.found);
    w2 = root spawn EntryWalk(claimed={});
    print(w2.claimed);
}
