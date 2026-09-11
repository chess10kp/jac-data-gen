"""agent-team-project/kensho-projects#17 — Workplane M2E lifecycle and dependency DAG."""

glob LIFECYCLE = frozenset({"open", "in_progress", "in_review", "done", "cancelled"});
glob DEP_TYPES = frozenset({"blocks", "relates", "caused-by"});

class DependencyCycleError(Exception) {}

node WorkItem {
    has iid: str;
    has state: str;
    has version: int;
}

edge Blocks: WorkItem --> WorkItem {}

obj Workplane {
    has items: dict[str, dict] = {};
    has relates: dict[str, list[tuple[str, str]]] = {};
}

walker BlockerClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with WorkItem entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        if here.iid != self.origin { self.found.append(here.iid); }
        visit [here ->:Blocks:->][?:WorkItem];
    }
}

def _find_item(item_id: str) -> WorkItem | None {
    for nd in [root-->[?:WorkItem]] {
        if nd.iid == item_id { return nd; }
    }
    return None;
}

def _transition_allowed(cur: str, target: str) -> bool {
    if cur == "open" {
        return target == "in_progress" or target == "cancelled";
    }
    if cur == "in_progress" {
        return target == "in_review" or target == "cancelled";
    }
    if cur == "in_review" {
        return target == "in_progress" or target == "done" or target == "cancelled";
    }
    return False;
}

def load_workplane(
    items: list[tuple[str, str, int]],
    dependencies: list[tuple[str, str, str]],
) -> Workplane {
    wp = Workplane();
    for entry in items {
        iid = entry[0];
        st = entry[1];
        ver = entry[2];
        wp.items[iid] = {"state": st, "version": ver};
        nd = WorkItem(iid=iid, state=st, version=ver);
        root ++> nd;
    }
    for dep in dependencies {
        src = dep[0];
        tgt = dep[1];
        dtype = dep[2];
        if not (src in wp.items) or not (tgt in wp.items) { continue; }
        if dtype not in DEP_TYPES { continue; }
        if dtype == "blocks" {
            s = _find_item(src);
            t = _find_item(tgt);
            if s is not None and t is not None { t +>:Blocks:+> s; }
        } else {
            if not (src in wp.relates) { wp.relates[src] = []; }
            wp.relates[src].append((tgt, dtype));
            if not (tgt in wp.relates) { wp.relates[tgt] = []; }
            wp.relates[tgt].append((src, dtype));
        }
    }
    return wp;
}

def get_state(wp: Workplane, item_id: str) -> str | None {
    row = wp.items.get(item_id, None);
    if row is None { return None; }
    return str(row["state"]);
}

def blocking_closure(wp: Workplane, item_id: str) -> list[str] {
    if not (item_id in wp.items) { return []; }
    nd = _find_item(item_id);
    if nd is None { return []; }
    w = nd spawn BlockerClosure(claimed={}, found=[], origin=item_id);
    return sorted(w.found);
}

def is_blocked(wp: Workplane, item_id: str) -> bool {
    if not (item_id in wp.items) { return False; }
    for bid in blocking_closure(wp, item_id) {
        row = wp.items.get(bid, None);
        if row is not None and str(row["state"]) != "done" { return True; }
    }
    return False;
}

def would_block_cycle(wp: Workplane, blocker: str, blocked: str) -> bool {
    if blocker == blocked { return True; }
    nd = _find_item(blocker);
    if nd is None { return False; }
    w = nd spawn BlockerClosure(claimed={}, found=[], origin=blocker);
    for hit in w.found {
        if hit == blocked { return True; }
    }
    return False;
}

def add_dependency(wp: Workplane, source: str, target: str, dep_type: str) -> None {
    if dep_type not in DEP_TYPES {
        raise ValueError(f"unknown dependency type: {dep_type}");
    }
    if not (source in wp.items) or not (target in wp.items) { return; }
    if dep_type == "blocks" {
        if would_block_cycle(wp, source, target) {
            raise DependencyCycleError("dependency_cycle");
        }
        s = _find_item(source);
        t = _find_item(target);
        if s is not None and t is not None { t +>:Blocks:+> s; }
        return;
    }
    if not (source in wp.relates) { wp.relates[source] = []; }
    wp.relates[source].append((target, dep_type));
    if not (target in wp.relates) { wp.relates[target] = []; }
    wp.relates[target].append((source, dep_type));
}

def remove_dependency(wp: Workplane, source: str, target: str, dep_type: str) -> bool {
    if dep_type not in DEP_TYPES {
        raise ValueError(f"unknown dependency type: {dep_type}");
    }
    if not (source in wp.items) or not (target in wp.items) { return False; }
    if dep_type == "blocks" {
        bl_row = wp.items.get(target, None);
        if bl_row is None { return False; }
        s = _find_item(source);
        t = _find_item(target);
        if s is None or t is None { return False; }
        linked = False;
        for blk in [t ->:Blocks:->][?:WorkItem] {
            if blk.iid == source { linked = True; }
        }
        if not linked { return False; }
        t del ->:Blocks:-> s;
        return True;
    }
    pairs = wp.relates.get(source, []);
    if (target, dep_type) not in pairs { return False; }
    pairs.remove((target, dep_type));
    wp.relates[target].remove((source, dep_type));
    return True;
}

def transition(wp: Workplane, item_id: str, target: str, expected_version: int) -> int {
    row = wp.items.get(item_id, None);
    if row is None { raise KeyError(item_id); }
    if int(row["version"]) != expected_version { raise ValueError("stale_version"); }
    cur = str(row["state"]);
    if not _transition_allowed(cur, target) { raise ValueError("invalid_transition"); }
    if (target == "in_progress" or target == "done") and is_blocked(wp, item_id) {
        raise ValueError("blocked");
    }
    row["state"] = target;
    row["version"] = expected_version + 1;
    nd = _find_item(item_id);
    if nd is not None {
        nd.state = target;
        nd.version = expected_version + 1;
    }
    return int(row["version"]);
}

def related_items(wp: Workplane, item_id: str) -> list[tuple[str, str]] {
    if not (item_id in wp.items) { return []; }
    return sorted(wp.relates.get(item_id, []));
}
