"""Credit-based DAG admission control for in-flight dataset caps.

nauticalab/orcapod-python#244
"""

node PNode {
    has nid: str;
    has role: str;
}

edge Flow {}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has terminals: list[str] = [];

    can walk with PNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print("reach", here.nid);
        if here.role == "terminal" {
            self.terminals.append(here.nid);
        }
        kids: list[PNode] = [];
        for ch in [here ->:Flow:->][?:PNode] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

obj CreditPool {
    has max_datasets_in_flight: int;
    has resident: int = 0;
}

obj DagHandle {
    has nodes: dict[str, PNode] = {};
}

def create_pool(max_datasets_in_flight: int) -> CreditPool {
    return CreditPool(max_datasets_in_flight=max_datasets_in_flight);
}

def dag_has_source(dag: DagHandle) -> bool {
    for nid in dag.nodes {
        nd = dag.nodes[nid] as PNode;
        if nd.role == "source" {
            return True;
        }
    }
    return False;
}

def build_dag(node_rows: list, edge_rows: list) -> DagHandle {
    dag = DagHandle();
    i = 0;
    while i < len(node_rows) {
        nid = node_rows[i][0];
        role = node_rows[i][1];
        nd = PNode(nid=nid, role=role);
        root ++> nd;
        dag.nodes[nid] = nd;
        i += 1;
    }
    j = 0;
    while j < len(edge_rows) {
        src_id = edge_rows[j][0];
        dst_id = edge_rows[j][1];
        if (src_id in dag.nodes) and (dst_id in dag.nodes) {
            a = dag.nodes[src_id] as PNode;
            b = dag.nodes[dst_id] as PNode;
            a +>:Flow:+> b;
        }
        j += 1;
    }
    return dag;
}

def admit(pool: CreditPool, dag: DagHandle) -> bool {
    if not dag_has_source(dag) {
        return False;
    }
    if pool.resident >= pool.max_datasets_in_flight {
        return False;
    }
    pool.resident += 1;
    return True;
}

def release_at_terminal(pool: CreditPool) -> None {
    if pool.resident > 0 {
        pool.resident -= 1;
    }
}

def count_in_flight(pool: CreditPool) -> int {
    return pool.resident;
}

def terminal_ids_reachable(dag: DagHandle, start: str) -> list[str] {
    if start not in dag.nodes {
        return [];
    }
    start_nd = dag.nodes[start] as PNode;
    w = start_nd spawn ReachWalker(claimed={});
    out: list[str] = [];
    t = 0;
    while t < len(w.terminals) {
        out.append(w.terminals[t]);
        t += 1;
    }
    return sorted(out);
}

test "credit cap blocks excess admits" {
    pool = create_pool(2);
    dag = build_dag(
        [("src", "source"), ("clean", "terminal")],
        [("src", "clean")]
    );
    assert admit(pool, dag);
    assert admit(pool, dag);
    assert not admit(pool, dag);
    assert count_in_flight(pool) == 2;;
}

test "release frees admission slot" {
    pool = create_pool(1);
    dag = build_dag(
        [("src", "source"), ("done", "terminal")],
        [("src", "done")]
    );
    assert admit(pool, dag);
    assert not admit(pool, dag);
    release_at_terminal(pool);
    assert count_in_flight(pool) == 0;
    assert admit(pool, dag);;
}

test "diamond revisit yields one terminal" {
    dag = build_dag(
        [
            ("src", "source"),
            ("mid_l", "stage"),
            ("mid_r", "stage"),
            ("sink", "terminal")
        ],
        [
            ("src", "mid_l"),
            ("src", "mid_r"),
            ("mid_r", "mid_l"),
            ("mid_l", "sink"),
            ("mid_r", "sink")
        ]
    );
    got = terminal_ids_reachable(dag, "src");
    assert got == ["sink"];
    assert len(got) == 1;;
}

test "unknown start id tolerated" {
    dag = build_dag(
        [("src", "source"), ("sink", "terminal")],
        [("src", "sink")]
    );
    assert terminal_ids_reachable(dag, "missing") == [];;
}

test "admit without source rejected" {
    pool = create_pool(3);
    dag = build_dag(
        [("only_stage", "stage"), ("sink", "terminal")],
        [("only_stage", "sink")]
    );
    assert not admit(pool, dag);
    assert count_in_flight(pool) == 0;;
}

test "release below zero does not go negative" {
    pool = create_pool(2);
    release_at_terminal(pool);
    release_at_terminal(pool);
    assert count_in_flight(pool) == 0;;
}
