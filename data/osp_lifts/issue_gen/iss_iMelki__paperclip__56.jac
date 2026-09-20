"""Owned Vitest scratch-root custody, quiescence, and cascade cleanup.
iMelki/paperclip#56
"""

node ScratchRoot {
    has cid: str;
    has tag: str;
    has bytes: int = 0;
    has child_count: int = 0;
    has temp_env: dict[str, str] = {};
    has cleanup_result: str = "pending";
    has present: bool = True;
    has locked: bool = False;
    has exit_status: int = 0;
    has duration_ms: int = 0;
}

node ChildProc {
    has cid: str;
    has pid: int;
    has alive: bool = True;
}

node Manifest {
    has cid: str;
    has owner_tag: str;
    has valid: bool = True;
}

edge Owns {}
edge Custody {}

walker QuiesceWalk {
    has claimed: dict[str, bool] = {};
    has all_dead: bool = True;

    can scan_proc with ChildProc entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print ["quiesce_proc", here.cid, here.alive];
        if here.alive { self.all_dead = False; }
    }

    can scan_scratch with ScratchRoot entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print ["quiesce_root", here.cid];
        proc_kids: list = [];
        for ch in [here ->:Custody:->][?:ChildProc] { proc_kids.append(ch); }
        sub_kids: list = [];
        for sr in [here ->:Owns:->][?:ScratchRoot] { sub_kids.append(sr); }
        has_more: bool = False;
        if len(proc_kids) > 0 { visit :0: proc_kids; has_more = True; }
        if len(sub_kids) > 0 { visit :0: sub_kids; has_more = True; }
        if not has_more { disengage; }
    }
}

walker CollectRemoveWalk {
    has claimed: dict[str, bool] = {};
    has cids: list[str] = [];

    can grab_proc with ChildProc entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.cids.append(here.cid);
        print ["collect_proc", here.cid];
    }

    can grab_scratch with ScratchRoot entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.cids.append(here.cid);
        print ["collect_root", here.cid];
        proc_kids: list = [];
        for ch in [here ->:Custody:->][?:ChildProc] { proc_kids.append(ch); }
        sub_kids: list = [];
        for sr in [here ->:Owns:->][?:ScratchRoot] { sub_kids.append(sr); }
        has_more: bool = False;
        if len(proc_kids) > 0 { visit :0: proc_kids; has_more = True; }
        if len(sub_kids) > 0 { visit :0: sub_kids; has_more = True; }
        if not has_more { disengage; }
    }
}

def _find_root(root_id: str) -> ScratchRoot | None {
    for nd in [root -->] {
        if nd is ScratchRoot and nd.cid == root_id { return nd; }
    }
    return None;
}

def allocate_scratch_root(tag: str) -> str {
    rid: str = "eph-paperclip-vitest-" + tag;
    nd = ScratchRoot(cid=rid, tag=tag);
    root ++> nd;
    return rid;
}

def normalize_temp_env(root_id: str) -> dict[str, str] {
    nd = _find_root(root_id);
    if nd is None { return {}; }
    path: str = "/owned/" + root_id;
    env: dict[str, str] = {};
    env["TEMP"] = path;
    env["TMP"] = path;
    env["TMPDIR"] = path;
    nd.temp_env = env;
    return env;
}

def write_ownership_manifest(root_id: str, owner_tag: str) -> bool {
    nd = _find_root(root_id);
    if nd is None { return False; }
    mf = Manifest(cid=root_id + ":manifest", owner_tag=owner_tag, valid=True);
    nd +>:Owns:+> mf;
    return True;
}

def register_child(root_id: str, pid: int, alive: bool) -> bool {
    nd = _find_root(root_id);
    if nd is None { return False; }
    cid: str = root_id + ":pid:" + str(pid);
    ch = ChildProc(cid=cid, pid=pid, alive=alive);
    nd +>:Custody:+> ch;
    nd.child_count = nd.child_count + 1;
    return True;
}

def child_tree_quiescent(root_id: str) -> bool {
    nd = _find_root(root_id);
    if nd is None { return True; }
    w = nd spawn QuiesceWalk(claimed={}, all_dead=True);
    print ["quiescent", root_id, w.all_dead];
    return w.all_dead;
}

def cascade_remove_root(root_id: str) -> str {
    nd = _find_root(root_id);
    if nd is None { return "missing"; }
    if nd.locked { return "busy"; }
    if not child_tree_quiescent(root_id) { return "busy"; }
    w = nd spawn CollectRemoveWalk(claimed={}, cids=[]);
    collected: list[str] = w.cids;
    for cid in collected {
        for item in [root -->] {
            if item is ScratchRoot and item.cid == cid { item.present = False; }
            if item is ChildProc and item.cid == cid { item.alive = False; }
        }
    }
    nd.cleanup_result = "removed";
    return "removed";
}

def verify_root_absent(root_id: str) -> bool {
    nd = _find_root(root_id);
    if nd is None { return True; }
    return not nd.present;
}

def build_cleanup_receipt(root_id: str, exit_status: int, duration_ms: int) -> dict[str, str] {
    receipt: dict[str, str] = {};
    nd = _find_root(root_id);
    receipt["exit_status"] = str(exit_status);
    receipt["duration_ms"] = str(duration_ms);
    if nd is None {
        receipt["cleanup_result"] = "missing";
        receipt["logical_bytes"] = "0";
        receipt["child_count"] = "0";
        receipt["caller_tag"] = "";
        receipt["residual_paths"] = root_id;
        return receipt;
    }
    receipt["logical_bytes"] = str(nd.bytes);
    receipt["child_count"] = str(nd.child_count);
    receipt["cleanup_result"] = nd.cleanup_result;
    receipt["caller_tag"] = nd.tag;
    residual: str = "";
    if nd.present { residual = nd.cid; }
    receipt["residual_paths"] = residual;
    return receipt;
}

def cleanup_execution(root_id: str, exit_status: int, duration_ms: int) -> dict[str, str] {
    normalize_temp_env(root_id);
    write_ownership_manifest(root_id, "stable-runner");
    result: str = cascade_remove_root(root_id);
    nd = _find_root(root_id);
    if nd is not None {
        nd.exit_status = exit_status;
        nd.duration_ms = duration_ms;
        if nd.cleanup_result == "pending" { nd.cleanup_result = result; }
    }
    return build_cleanup_receipt(root_id, exit_status, duration_ms);
}
