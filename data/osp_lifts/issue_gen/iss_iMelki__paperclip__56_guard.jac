# iss_iMelki__paperclip__56.jac — owned vitest scratch root custody graph

node ScratchRoot {
    has cid: str;
    has caller_tag: str = "";
    has logical_bytes: int = 0;
    has removed: bool = False;
}

node Proc {
    has pid: str;
    has state: str = "quiescent";
}

node Manifest {
    has owner_tag: str;
    has valid: bool = True;
}

edge Owns {}
edge Nested {}

walker FindRoot {
    has want: str;
    has claimed: dict[str, bool] = {};
    has hit: ScratchRoot | None = None;

    can step with ScratchRoot entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.want {
            self.hit = here;
        }
        kids: list[ScratchRoot] = [here ->:Nested:->][?:ScratchRoot];
        visit :0: kids;
        print({"find": here.cid, "want": self.want});
    }
}

walker CollectProcs {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with ScratchRoot entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        procs: list[Proc] = [here ->:Owns:->][?:Proc];
        for p in procs {
            self.found.append(p.pid);
        }
        kids: list[ScratchRoot] = [here ->:Nested:->][?:ScratchRoot];
        visit :0: kids;
        print({"collect": here.cid, "count": len(self.found)});
    }
}

walker QuiesceCheck {
    has claimed: dict[str, bool] = {};
    has blocked: bool = False;

    can step with ScratchRoot entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        procs: list[Proc] = [here ->:Owns:->][?:Proc];
        for p in procs {
            if p.state != "quiescent" {
                self.blocked = True;
            }
        }
        kids: list[ScratchRoot] = [here ->:Nested:->][?:ScratchRoot];
        visit :0: kids;
        print({"quiesce": here.cid, "blocked": self.blocked});
    }
}

def allocate_owned_root(caller_tag: str, stamp: str, nonce: str) -> str {
    cid = "eph-paperclip-vitest-" + stamp + "-" + nonce;
    nd = ScratchRoot(cid=cid, caller_tag=caller_tag);
    root ++> nd;
    return cid;
}

def normalize_temp_triplet(root_path: str) -> dict[str, str] {
    env: dict[str, str] = {};
    env["TEMP"] = root_path;
    env["TMP"] = root_path;
    env["TMPDIR"] = root_path;
    return env;
}

def write_owner_manifest(root_node: ScratchRoot, owner_tag: str) -> bool {
    if owner_tag == "" {
        return False;
    }
    mf = Manifest(owner_tag=owner_tag, valid=True);
    root_node ++> mf;
    return True;
}

def validate_manifest(mf: Manifest) -> bool {
    if not mf.valid {
        return False;
    }
    if mf.owner_tag == "" {
        return False;
    }
    return True;
}

def attach_proc(root_node: ScratchRoot, pid: str, state: str) -> bool {
    p = Proc(pid=pid, state=state);
    root_node +>:Owns:+> p;
    return True;
}

def collect_child_pids(root_node: ScratchRoot) -> list[str] {
    wk = root_node spawn CollectProcs(claimed={}, found=[]);
    out: list[str] = [];
    for pid in wk.found {
        out.append(pid);
    }
    return sorted(out);
}

def collect_child_pids_for_cid(graph_anchor: ScratchRoot, cid: str) -> list[str] {
    fw = graph_anchor spawn FindRoot(want=cid, claimed={}, hit=None);
    if fw.hit is None {
        return [];
    }
    wk = fw.hit spawn CollectProcs(claimed={}, found=[]);
    out: list[str] = [];
    for pid in wk.found {
        out.append(pid);
    }
    return sorted(out);
}

def children_quiescent(root_node: ScratchRoot) -> bool {
    wk = root_node spawn QuiesceCheck(claimed={}, blocked=False);
    return not wk.blocked;
}

def remove_owned_root(root_node: ScratchRoot) -> dict[str, str] {
    result: dict[str, str] = {};
    if not children_quiescent(root_node) {
        result["cleanup"] = "EBUSY";
        result["residual"] = root_node.cid;
        return result;
    }
    root_node.removed = True;
    result["cleanup"] = "ok";
    result["residual"] = "";
    return result;
}

def verify_absent(cid: str, alive: list[str] | None) -> bool {
    ids: list[str] = [];
    if alive is not None {
        for x in alive {
            ids.append(x);
        }
    }
    for x in ids {
        if x == cid {
            return False;
        }
    }
    return True;
}

def build_terminal_receipt(
    duration_ms: int,
    exit_status: int,
    logical_bytes: int,
    child_count: int,
    cleanup: str,
    residual: str,
    caller_tag: str
) -> dict[str, str] {
    rec: dict[str, str] = {};
    rec["duration_ms"] = str(duration_ms);
    rec["exit_status"] = str(exit_status);
    rec["logical_bytes"] = str(logical_bytes);
    rec["child_count"] = str(child_count);
    rec["cleanup"] = cleanup;
    rec["residual"] = residual;
    rec["caller_tag"] = caller_tag;
    return rec;
}

test "allocate_and_normalize" {
    cid = allocate_owned_root("vitest", "20250915", "n1");
    assert cid == "eph-paperclip-vitest-20250915-n1";
    env = normalize_temp_triplet("/scratch/vitest");
    assert env["TEMP"] == "/scratch/vitest";
    assert env["TMPDIR"] == "/scratch/vitest";
}

test "manifest_write_validate" {
    nd = ScratchRoot(cid="r-mf", caller_tag="ct");
    root ++> nd;
    assert write_owner_manifest(nd, "") == False;
    assert write_owner_manifest(nd, "owner-a") == True;
    mfs: list[Manifest] = [nd ->][?:Manifest];
    assert len(mfs) == 1;
    assert validate_manifest(mfs[0]) == True;
}

test "collect_child_pids_sorted" {
    nd = ScratchRoot(cid="r-col");
    root ++> nd;
    attach_proc(nd, "p2", "quiescent");
    attach_proc(nd, "p1", "quiescent");
    assert collect_child_pids(nd) == ["p1", "p2"];
}

test "collect_for_nested_cid" {
    parent = ScratchRoot(cid="r-par");
    child = ScratchRoot(cid="r-ch");
    root ++> parent;
    parent +>:Nested:+> child;
    attach_proc(child, "cp1", "quiescent");
    assert collect_child_pids_for_cid(parent, "missing") == [];
    assert collect_child_pids_for_cid(parent, "r-ch") == ["cp1"];
}

test "remove_busy_when_not_quiescent" {
    nd = ScratchRoot(cid="r-busy");
    root ++> nd;
    attach_proc(nd, "px", "running");
    res = remove_owned_root(nd);
    assert res["cleanup"] == "EBUSY";
    assert res["residual"] == "r-busy";
    assert nd.removed == False;
}

test "remove_ok_and_receipt" {
    nd = ScratchRoot(cid="r-ok", caller_tag="tag-z");
    root ++> nd;
    attach_proc(nd, "py", "quiescent");
    res = remove_owned_root(nd);
    assert res["cleanup"] == "ok";
    assert res["residual"] == "";
    assert nd.removed == True;
    rec = build_terminal_receipt(12, 0, 64, 1, "ok", "", "tag-z");
    assert rec["child_count"] == "1";
    assert verify_absent("gone", ["alive"]) == True;
    assert verify_absent("alive", ["alive"]) == False;
}
