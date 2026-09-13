node CandidateSha { has sha: str; has qualified: bool = False; }
node MatrixRow { has rid: str; has status: str = "BLOCKED"; has timing_ms: int = 0; has dpi_pct: int = 100; }
node Prereq { has pid: str; has available: bool = False; }
node QualGraph { has lane_key: str = "local-agent-e-local010-runtime-20260825"; has qualified: bool = False; }

edge WorkflowEdge {}
edge RequiresEdge {}
edge Anchors {}

walker RowClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has nodes: list[MatrixRow] = [];
    can traverse with MatrixRow entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        self.found.append(here.rid);
        self.nodes.append(here);
        for nxt in [here ->:WorkflowEdge:->][?:MatrixRow] {
            visit :0: [nxt];
        }
        print(here.rid);
    }
}

walker FullDepWalker {
    has claimed: dict[str, bool] = {};
    has rows: list[str] = [];
    has prereqs: list[str] = [];
    can step_row with MatrixRow entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        self.rows.append(here.rid);
        for nxt in [here ->:WorkflowEdge:->][?:MatrixRow] {
            visit :0: [nxt];
        }
        for pre in [here ->:RequiresEdge:->][?:Prereq] {
            visit :0: [pre];
        }
        print(here.rid);
    }
    can step_pre with Prereq entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.prereqs.append(here.pid);
        print(here.pid);
    }
}

def create_qual_graph(lane_key: str) -> QualGraph {
    g = QualGraph(lane_key=lane_key);
    root ++> g;
    return g;
}
def add_row(graph_root: QualGraph, rid: str, status: str) -> MatrixRow {
    r = MatrixRow(rid=rid, status=status);
    graph_root +>:Anchors:+> r;
    return r;
}
def add_prereq(graph_root: QualGraph, pid: str, available: bool) -> Prereq {
    p = Prereq(pid=pid, available=available);
    graph_root +>:Anchors:+> p;
    return p;
}
def add_dependency(src: MatrixRow, dst: MatrixRow) -> None {
    src +>:WorkflowEdge:+> dst;
}
def add_requirement(row: MatrixRow, pre: Prereq) -> None {
    row +>:RequiresEdge:+> pre;
}
def find_row(graph_root: QualGraph, rid: str) -> MatrixRow | None {
    for cand in [graph_root ->:Anchors:->][?:MatrixRow] {
        if cand.rid == rid { return cand; }
    }
    return None;
}
def get_closure(start_row: MatrixRow) -> list[str] {
    w: RowClosure = start_row spawn RowClosure(claimed={}, found=[], nodes=[]);
    return w.found;
}
def get_closure_by_id(graph_root: QualGraph, rid: str) -> list[str] {
    row: MatrixRow | None = find_row(graph_root, rid);
    if row is None { return []; }
    w: RowClosure = row spawn RowClosure(claimed={}, found=[], nodes=[]);
    return w.found;
}
def get_blocked_rows(graph_root: QualGraph) -> list[str] {
    out: list[str] = [];
    for r in [graph_root ->:Anchors:->][?:MatrixRow] {
        if r.status == "BLOCKED" { out.append(r.rid); }
    }
    return out;
}
def is_local_pass(graph_root: QualGraph) -> bool {
    rows: list[MatrixRow] = [graph_root ->:Anchors:->][?:MatrixRow];
    if len(rows) == 0 { return False; }
    for r in rows {
        if r.status != "PASS" { return False; }
    }
    return True;
}
def cascade_block(start_row: MatrixRow, new_status: str) -> list[str] {
    w: RowClosure = start_row spawn RowClosure(claimed={}, found=[], nodes=[]);
    for n in w.nodes { n.status = new_status; }
    return w.found;
}
def get_required_prereqs(start_row: MatrixRow) -> list[str] {
    w: FullDepWalker = start_row spawn FullDepWalker(claimed={}, rows=[], prereqs=[]);
    return w.prereqs;
}

with entry {
    g = create_qual_graph("local-agent-e-local010-runtime-20260825");
    a = add_row(g, "R01", "BLOCKED");
    b = add_row(g, "R02", "BLOCKED");
    add_dependency(a, b);
    w: RowClosure = a spawn RowClosure(claimed={}, found=[], nodes=[]);
    print(w.found);
}
