"""b-at-neu/port#52 — Pipeline checkout branch visibility and workflow dependency reach."""

glob _REQUIRED: list[str] = [".claude/port.config.json", ".claude/settings.json"];

node Branch {
    has bid: str;
    has artifacts: list[str] = [];
    has allow_ok: bool = False;
}

node Ticket {
    has tid: str;
}

edge ChildOf {}
edge BlockedBy {}

obj PipelineHandle {
    has branches: dict[str, bool] = {};
    has parent_of: dict[str, str | None] = {};
    has artifacts: dict[str, list[str]] = {};
    has allow_flags: dict[str, bool] = {};
    has tickets: dict[str, bool] = {};
    has blocked_by: dict[str, list[str]] = {};
}

walker BlockerClosureWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has origin: str = "";
    has bootstrapped: bool = False;

    can step with Ticket entry {
        if here.tid == self.origin and not self.bootstrapped {
            self.bootstrapped = True;
            visit [here ->:BlockedBy:->][?:Ticket];
            skip;
        }
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.reached.append(here.tid);
        visit [here ->:BlockedBy:->][?:Ticket];
    }
}

walker DepPathWalk {
    has trail: list[str] = [];
    has on_path: dict[str, bool] = {};
    has paths: list[list[str]] = [];
    has target: str = "";
    has max_depth: int = 12;

    can step with Ticket entry {
        if here.tid in self.on_path { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.tid);
        nop: dict[str, bool] = {**self.on_path, here.tid: True};
        if len(nt) > self.max_depth { skip; }
        if here.tid == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        blockers = [here ->:BlockedBy:->][?:Ticket];
        nms: list[str] = [];
        for n in blockers { nms.append(n.tid); }
        for nm in sorted(nms) {
            for n in blockers {
                if n.tid == nm {
                    n spawn DepPathWalk(
                        trail=nt,
                        on_path=nop,
                        paths=self.paths,
                        target=self.target,
                        max_depth=self.max_depth,
                    );
                }
            }
        }
    }
}

walker LineagePathWalk {
    has trail: list[str] = [];
    has on_path: dict[str, bool] = {};
    has paths: list[list[str]] = [];
    has target: str = "";
    has max_depth: int = 12;

    can step with Branch entry {
        if here.bid in self.on_path { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.bid);
        nop: dict[str, bool] = {**self.on_path, here.bid: True};
        if len(nt) > self.max_depth { skip; }
        if here.bid == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        parents = [here ->:ChildOf:->][?:Branch];
        nms: list[str] = [];
        for n in parents { nms.append(n.bid); }
        for nm in sorted(nms) {
            for n in parents {
                if n.bid == nm {
                    n spawn LineagePathWalk(
                        trail=nt,
                        on_path=nop,
                        paths=self.paths,
                        target=self.target,
                        max_depth=self.max_depth,
                    );
                }
            }
        }
    }
}

def _branch_node(bid: str) -> Branch | None {
    for b in [root -->][?:Branch] {
        if b.bid == bid { return b; }
    }
    return None;
}

def _ticket_node(tid: str) -> Ticket | None {
    for t in [root -->][?:Ticket] {
        if t.tid == tid { return t; }
    }
    return None;
}

def load_pipeline(
    branch_ids: list[str],
    parent_edges: list[tuple[str, str]],
    branch_artifacts: list[tuple[str, list[str]]],
    branch_allow: list[tuple[str, bool]],
    ticket_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> PipelineHandle {
    p = PipelineHandle();
    for b in branch_ids {
        p.branches[b] = True;
        p.parent_of[b] = None;
        p.artifacts[b] = [];
        p.allow_flags[b] = False;
        root ++> Branch(bid=b);
    }
    for (child, parent) in parent_edges {
        if not (child in p.branches) or not (parent in p.branches) {
            raise KeyError("unknown branch");
        }
        p.parent_of[child] = parent;
        c = _branch_node(child);
        par = _branch_node(parent);
        if c is not None and par is not None { c +>:ChildOf:+> par; }
    }
    for (branch, arts) in branch_artifacts {
        if not (branch in p.branches) { raise KeyError("unknown branch"); }
        p.artifacts[branch] = arts;
        bnd = _branch_node(branch);
        if bnd is not None { bnd.artifacts = arts; }
    }
    for (branch, ok) in branch_allow {
        if not (branch in p.branches) { raise KeyError("unknown branch"); }
        p.allow_flags[branch] = bool(ok);
        bnd = _branch_node(branch);
        if bnd is not None { bnd.allow_ok = bool(ok); }
    }
    for tid in ticket_ids {
        p.tickets[tid] = True;
        p.blocked_by[tid] = [];
        root ++> Ticket(tid=tid);
    }
    for (ticket, blocker) in depends_edges {
        if not (ticket in p.tickets) or not (blocker in p.tickets) {
            raise KeyError("unknown ticket");
        }
        p.blocked_by[ticket].append(blocker);
        t = _ticket_node(ticket);
        blk = _ticket_node(blocker);
        if t is not None and blk is not None { t +>:BlockedBy:+> blk; }
    }
    return p;
}

def branches_carrying(pipeline: PipelineHandle, artifact: str) -> list[str] {
    out: list[str] = [];
    for b in sorted(pipeline.branches.keys()) {
        if artifact in pipeline.artifacts.get(b, []) { out.append(b); }
    }
    return out;
}

def preflight_checkout(pipeline: PipelineHandle, checkout_branch: str) -> list[str] {
    if not (checkout_branch in pipeline.branches) { return ["unknown checkout branch"]; }
    msgs: list[str] = [];
    on_disk = pipeline.artifacts.get(checkout_branch, []);
    for req in _REQUIRED {
        if req not in on_disk {
            carriers = branches_carrying(pipeline, req);
            hint = "";
            if len(carriers) > 0 { hint = f"; present on {', '.join(carriers)}"; }
            msgs.append(f"missing {req} on {checkout_branch}{hint}");
        }
    }
    if ".claude/settings.json" in on_disk and not pipeline.allow_flags.get(checkout_branch, False) {
        msgs.append(f"missing permissions.allow in .claude/settings.json on {checkout_branch}");
    }
    return sorted(msgs);
}

def blocker_closure(pipeline: PipelineHandle, ticket: str) -> list[str] {
    if not (ticket in pipeline.tickets) { return []; }
    nd = _ticket_node(ticket);
    if nd is None { return []; }
    w = nd spawn BlockerClosureWalk(claimed={}, reached=[], origin=ticket, bootstrapped=False);
    return sorted(w.reached);
}

def ready_tickets(pipeline: PipelineHandle, completed: list[str] | None = None) -> list[str] {
    done: dict[str, bool] = {};
    if completed is not None { for c in completed { done[c] = True; } }
    out: list[str] = [];
    for tid in sorted(pipeline.tickets.keys()) {
        if tid in done { continue; }
        ok = True;
        for b in pipeline.blocked_by.get(tid, []) {
            if not (b in done) { ok = False; }
        }
        if ok { out.append(tid); }
    }
    return out;
}

def dependency_paths(
    pipeline: PipelineHandle,
    ticket: str,
    blocker: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if not (ticket in pipeline.tickets) or not (blocker in pipeline.tickets) { return []; }
    nd = _ticket_node(ticket);
    if nd is None { return []; }
    w = nd spawn DepPathWalk(trail=[], on_path={}, paths=[], target=blocker, max_depth=max_depth);
    out: list[list[str]] = [];
    for pth in w.paths {
        row: list[str] = [];
        for x in pth { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def lineage_paths(
    pipeline: PipelineHandle,
    from_branch: str,
    to_branch: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if not (from_branch in pipeline.branches) or not (to_branch in pipeline.branches) { return []; }
    nd = _branch_node(from_branch);
    if nd is None { return []; }
    w = nd spawn LineagePathWalk(trail=[], on_path={}, paths=[], target=to_branch, max_depth=max_depth);
    out: list[list[str]] = [];
    for pth in w.paths {
        row: list[str] = [];
        for x in pth { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

test "blocker closure diamond revisit and cycle" {
    p = load_pipeline(
        [],
        [],
        [],
        [],
        ["goal", "left", "right", "hub", "ping"],
        [
            ("goal", "left"),
            ("goal", "right"),
            ("left", "hub"),
            ("right", "hub"),
            ("hub", "ping"),
            ("ping", "hub"),
        ],
    );
    assert blocker_closure(p, "goal") == ["hub", "left", "ping", "right"];
    assert blocker_closure(p, "hub") == ["hub", "ping"];
    assert blocker_closure(p, "missing") == [];
}

test "unknown branch and ticket tolerance" {
    p = load_pipeline(
        ["main"],
        [],
        [("main", [".claude/port.config.json"])],
        [],
        ["only"],
        [],
    );
    assert branches_carrying(p, "ghost") == [];
    assert preflight_checkout(p, "ghost") == ["unknown checkout branch"];
    assert lineage_paths(p, "main", "ghost") == [];
    assert lineage_paths(p, "ghost", "main") == [];
    assert dependency_paths(p, "only", "ghost") == [];
    assert dependency_paths(p, "ghost", "only") == [];
    assert ready_tickets(p, ["ghost", "only"]) == [];
}

test "dependency paths diamond depth and self" {
    p = load_pipeline(
        [],
        [],
        [],
        [],
        ["task", "arm_a", "arm_b", "root", "loop_a", "loop_b", "loop_c"],
        [
            ("task", "arm_a"),
            ("task", "arm_b"),
            ("arm_a", "root"),
            ("arm_b", "root"),
            ("loop_a", "loop_b"),
            ("loop_b", "loop_c"),
            ("loop_c", "loop_a"),
        ],
    );
    assert dependency_paths(p, "task", "root") == [
        ["task", "arm_a", "root"],
        ["task", "arm_b", "root"],
    ];
    assert dependency_paths(p, "task", "root", max_depth=2) == [];
    assert dependency_paths(p, "task", "task") == [["task"]];
    assert dependency_paths(p, "loop_a", "loop_c", max_depth=2) == [];
    assert dependency_paths(p, "loop_a", "loop_c", max_depth=3) == [["loop_a", "loop_b", "loop_c"]];
}

test "lineage paths self depth and unknown ids" {
    p = load_pipeline(
        ["feat", "dev", "main"],
        [("feat", "dev"), ("dev", "main")],
        [],
        [],
        [],
        [],
    );
    assert lineage_paths(p, "feat", "main") == [["feat", "dev", "main"]];
    assert lineage_paths(p, "feat", "main", max_depth=2) == [];
    assert lineage_paths(p, "main", "main") == [["main"]];
    assert lineage_paths(p, "feat", "ghost") == [];
    assert lineage_paths(p, "ghost", "main") == [];
}

test "preflight checkout carrier hints and allow gate" {
    p = load_pipeline(
        ["checkout", "alpha", "beta", "locked"],
        [],
        [
            ("checkout", []),
            ("alpha", [".claude/port.config.json"]),
            ("beta", [".claude/port.config.json", ".claude/settings.json"]),
            ("locked", [".claude/settings.json"]),
        ],
        [
            ("checkout", False),
            ("alpha", True),
            ("beta", True),
            ("locked", False),
        ],
        [],
        [],
    );
    assert preflight_checkout(p, "checkout") == [
        "missing .claude/port.config.json on checkout; present on alpha, beta",
        "missing .claude/settings.json on checkout; present on beta, locked",
    ];
    assert preflight_checkout(p, "locked") == [
        "missing .claude/port.config.json on locked; present on alpha, beta",
        "missing permissions.allow in .claude/settings.json on locked",
    ];
}

test "ready tickets conjunctive blockers" {
    p = load_pipeline(
        [],
        [],
        [],
        [],
        ["ship", "gate_a", "gate_b", "base"],
        [
            ("ship", "gate_a"),
            ("ship", "gate_b"),
            ("gate_a", "base"),
            ("gate_b", "base"),
        ],
    );
    assert ready_tickets(p) == ["base"];
    assert ready_tickets(p, ["base"]) == ["gate_a", "gate_b"];
    assert ready_tickets(p, ["base", "gate_a", "gate_b"]) == ["ship"];
    assert ready_tickets(p, ["base", "gate_a", "gate_b", "ship"]) == [];
}
