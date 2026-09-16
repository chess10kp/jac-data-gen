"""Vitest scratch root custody and cleanup — iMelki/paperclip#56."""

node EphemeralRoot {
    has cid: str;
    has caller_tag: str = "";
    has alive: bool = True;
    has locked: bool = False;
}

node ChildProc {
    has cid: str;
    has pid: int = 0;
    has running: bool = True;
}

node EnvSlot {
    has name: str;
    has path: str = "";
}

node Manifest {
    has owner_tag: str = "";
    has valid: bool = True;
}

edge ParentOf {}
edge Binds {}
edge HasManifest {}

obj VitestScratchGraph {
    has by_id: dict[str, object] = {};
    has removed: dict[str, bool] = {};
}

def _slot_names -> list[str] {
    names: list[str] = [];
    names.append("TEMP");
    names.append("TMP");
    names.append("TMPDIR");
    return names;
}

def _find_root(store: VitestScratchGraph, root_id: str) -> EphemeralRoot | None {
    if root_id not in store.by_id {
        return None;
    }
    nd: object = store.by_id[root_id];
    if not (nd instanceof EphemeralRoot) {
        return None;
    }
    hit: EphemeralRoot = nd as EphemeralRoot;
    return hit;
}

def allocate_ephemeral_root(store: VitestScratchGraph, caller_tag: str) -> str {
    rid: str = "eph-paperclip-vitest-" + caller_tag;
    root_nd = EphemeralRoot(cid=rid, caller_tag=caller_tag);
    store.by_id[rid] = root_nd;
    root ++> root_nd;
    slot_names: list[str] = _slot_names();
    for slot_name in slot_names {
        slot = EnvSlot(name=slot_name, path=rid);
        sid: str = rid + ":" + slot_name;
        store.by_id[sid] = slot;
        root_nd +>:Binds:+> slot;
    }
    return rid;
}

def normalize_temp_env(store: VitestScratchGraph, root_id: str) -> dict[str, str] {
    out: dict[str, str] = {};
    root_nd = _find_root(store, root_id);
    if root_nd is None {
        return out;
    }
    slots: list[EnvSlot] = [root_nd ->:Binds:->][?:EnvSlot];
    for slot in slots {
        slot.path = root_id;
        out[slot.name] = root_id;
    }
    return out;
}

def write_owner_manifest(store: VitestScratchGraph, root_id: str, owner_tag: str) -> bool {
    root_nd = _find_root(store, root_id);
    if root_nd is None {
        return False;
    }
    man = Manifest(owner_tag=owner_tag, valid=True);
    mid: str = root_id + ":manifest";
    store.by_id[mid] = man;
    root_nd +>:HasManifest:+> man;
    return True;
}

def attach_child(store: VitestScratchGraph, root_id: str, child_id: str, pid: int) -> bool {
    root_nd = _find_root(store, root_id);
    if root_nd is None {
        return False;
    }
    ch = ChildProc(cid=child_id, pid=pid, running=True);
    store.by_id[child_id] = ch;
    root_nd +>:ParentOf:+> ch;
    return True;
}

walker CollectDescendants {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step_root with EphemeralRoot entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        kids: list[ChildProc] = [here ->:ParentOf:->][?:ChildProc];
        for kid in kids {
            visit :0: [kid];
        }
    }

    can step_child with ChildProc entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        kids: list[ChildProc] = [here ->:ParentOf:->][?:ChildProc];
        for kid in kids {
            visit :0: [kid];
        } else {
            disengage;
        }
    }
}

def collect_descendants(store: VitestScratchGraph, root_id: str) -> list[str] {
    root_nd = _find_root(store, root_id);
    if root_nd is None {
        return [];
    }
    w = root_nd spawn CollectDescendants(claimed={});
    print w.found;
    out: list[str] = [];
    for cid in w.found {
        out.append(cid);
    }
    out.sort();
    return out;
}

walker QuiescenceProbe {
    has claimed: dict[str, bool] = {};
    has quiet: bool = True;

    can probe_root with EphemeralRoot entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.locked {
            self.quiet = False;
        }
        kids: list[ChildProc] = [here ->:ParentOf:->][?:ChildProc];
        for kid in kids {
            visit :0: [kid];
        }
    }

    can probe_child with ChildProc entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.running {
            self.quiet = False;
        }
        kids: list[ChildProc] = [here ->:ParentOf:->][?:ChildProc];
        for kid in kids {
            visit :0: [kid];
        } else {
            disengage;
        }
    }
}

def await_quiescence(store: VitestScratchGraph, root_id: str) -> bool {
    root_nd = _find_root(store, root_id);
    if root_nd is None {
        return False;
    }
    w = root_nd spawn QuiescenceProbe(claimed={});
    print w.quiet;
    return w.quiet;
}

def verify_env_custody(store: VitestScratchGraph, root_id: str) -> bool {
    root_nd = _find_root(store, root_id);
    if root_nd is None {
        return False;
    }
    slots: list[EnvSlot] = [root_nd ->:Binds:->][?:EnvSlot];
    for slot in slots {
        if slot.path != root_id {
            return False;
        }
    }
    return True;
}

def cleanup_owned_root(store: VitestScratchGraph, root_id: str) -> dict[str, object] {
    receipt: dict[str, object] = {};
    receipt["root_id"] = root_id;
    receipt["cleanup_ok"] = False;
    empty_res: list[str] = [];
    receipt["residual"] = empty_res;
    root_nd = _find_root(store, root_id);
    if root_nd is None {
        miss: list[str] = [];
        miss.append(root_id);
        receipt["residual"] = miss;
        return receipt;
    }
    if not await_quiescence(store, root_id) {
        busy: list[str] = [];
        busy.append(root_id);
        receipt["residual"] = busy;
        return receipt;
    }
    to_drop: list[str] = collect_descendants(store, root_id);
    mid: str = root_id + ":manifest";
    if mid in store.by_id {
        to_drop.append(mid);
    }
    slot_names: list[str] = _slot_names();
    for sn in slot_names {
        sid: str = root_id + ":" + sn;
        if sid in store.by_id {
            to_drop.append(sid);
        }
    }
    to_drop.sort();
    for cid in to_drop {
        if cid in store.by_id {
            store.removed[cid] = True;
            del store.by_id[cid];
        }
    }
    receipt["cleanup_ok"] = True;
    left: list[str] = [];
    receipt["residual"] = left;
    return receipt;
}
