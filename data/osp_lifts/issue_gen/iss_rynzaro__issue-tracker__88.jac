"""rynzaro/issue-tracker#88 — Wayfinder: handing a sub-task to another user."""

obj WayfinderBoard { has tasks: dict[str, Task] = {}; }
node Task {
    has tid: str;
    has owner: str;
    has hander: str = "";
    has handee: str = "";
    has is_handover_root: bool = False;
}
edge ChildOf {}
edge References {}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    can step with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.hits.append(here.tid);
        visit [->:ChildOf:->][?:Task] else { disengage; };
    }
}

def build_board(
    tasks: list[str],
    owners: dict[str, str],
    child_of: list[tuple[str, str]],
    handovers: list[tuple[str, str, str]],
    refs: list[tuple[str, str]] | None = None,
) -> WayfinderBoard {
    g = WayfinderBoard();
    for tid in tasks {
        if tid not in g.tasks {
            nd = Task(tid=tid, owner=owners[tid]);
            root ++> nd;
            g.tasks[tid] = nd;
        }
    }
    for (child, parent) in child_of {
        p = g.tasks.get(parent, None);
        c = g.tasks.get(child, None);
        if p is None { continue; }
        if c is None { continue; }
        p +>:ChildOf:+> c;
    }
    for (hander, handee, root_task) in handovers {
        ho = g.tasks.get(root_task, None);
        if ho is None { continue; }
        ho.hander = hander;
        ho.handee = handee;
        ho.is_handover_root = True;
    }
    for (src, dst) in refs or [] {
        s = g.tasks.get(src, None);
        t = g.tasks.get(dst, None);
        if s is None { continue; }
        if t is None { continue; }
        s +>:References:+> t;
    }
    return g;
}

def handed_subtree(g: WayfinderBoard, root_task: str) -> list[str] {
    start = g.tasks.get(root_task, None);
    if start is None { return []; }
    w = start spawn SubtreeWalk();
    return sorted(w.hits);
}

def visible_roots(g: WayfinderBoard, user: str) -> list[str] {
    out: list[str] = [];
    for tid in sorted(g.tasks.keys()) {
        nd = g.tasks[tid];
        if nd.is_handover_root and nd.handee == user {
            out.append(tid);
            continue;
        }
        if nd.owner != user { continue; }
        parents = [nd <-:ChildOf:<-][?:Task];
        if not parents { out.append(tid); continue; }
        par = parents[0];
        if par.owner != user { out.append(tid); }
    }
    return out;
}

def downstream_order(g: WayfinderBoard, root_task: str) -> list[str] {
    return handed_subtree(g, root_task);
}

def subtree_reachable(g: WayfinderBoard, root_task: str, target: str) -> bool {
    return target in handed_subtree(g, root_task);
}

def ref_violations(g: WayfinderBoard, scope_root: str) -> list[str] {
    start = g.tasks.get(scope_root, None);
    if start is None { return []; }
    w = start spawn SubtreeWalk();
    scope: dict[str, bool] = {};
    for nm in w.hits { scope[nm] = True; }
    violations: list[str] = [];
    for nm in w.hits {
        ag = g.tasks[nm];
        for tgt in [ag ->:References:->][?:Task] {
            if tgt.tid not in scope {
                violations.append(f"{nm}->{tgt.tid}");
            }
        }
    }
    return sorted(violations);
}

def hander_for(g: WayfinderBoard, task: str) -> str | None {
    nd = g.tasks.get(task, None);
    if nd is None or not nd.is_handover_root { return None; }
    return nd.hander if nd.hander else None;
}

def can_see_hander(g: WayfinderBoard, task: str, viewer: str) -> bool {
    nd = g.tasks.get(task, None);
    if nd is None or not nd.is_handover_root { return False; }
    return viewer == nd.handee and nd.hander != "";
}
