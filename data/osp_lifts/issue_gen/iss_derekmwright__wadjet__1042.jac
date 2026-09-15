"""derekmwright/wadjet#1042 — recursive CTE coordinator routing on DAG plans."""

node Row {
    has cid: str;
    has n: int;
}

node GraphRoot {}

edge Next {}

walker ExpandRows {
    has limit: int;
    has rows: list[int] = [];
    has claimed: dict[str, bool] = {};

    can step with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.rows.append(here.n);
        print(here.n);
        if here.n >= self.limit {
            disengage;
        }
        kids: list[Row] = [here ->:Next:->][?:Row];
        next_kids: list[Row] = [];
        for ch in kids {
            if ch.n <= self.limit {
                next_kids.append(ch);
            }
        }
        if next_kids {
            visit :0: next_kids;
        } else {
            disengage;
        }
    }
}

walker CoordinatorDemo {
    has limit: int;

    can kick with GraphRoot entry {
        root spawn ExpandRows(limit=self.limit, claimed={});
        print("coordinator_demo");
    }
}

def connect_chain(nodes: list[Row]) -> None {
    i: int = 0;
    while i < len(nodes) - 1 {
        nodes[i] +>:Next:+> nodes[i + 1];
        i += 1;
    }
}

def build_linear_cte_graph(anchor: int, limit: int) -> Row {
    nodes: list[Row] = [];
    n: int = anchor;
    idx: int = 0;
    while n <= limit {
        cid: str = "r" + str(idx);
        nd = Row(cid=cid, n=n);
        nodes.append(nd);
        n += 1;
        idx += 1;
    }
    root ++> nodes[0];
    connect_chain(nodes);
    return nodes[0];
}

def build_diamond_cte_graph(anchor: int, limit: int) -> Row {
    head = Row(cid="d0", n=anchor);
    left = Row(cid="d1a", n=anchor + 1);
    right = Row(cid="d1b", n=anchor + 1);
    merge = Row(cid="d2", n=anchor + 2);
    root ++> head;
    head +>:Next:+> left;
    head +>:Next:+> right;
    left +>:Next:+> merge;
    right +>:Next:+> merge;
    if limit > anchor + 2 {
        tail = Row(cid="d3", n=anchor + 3);
        merge +>:Next:+> tail;
    }
    return head;
}

def expand_recursive_cte(anchor: int, limit: int, diamond: bool = False) -> list[int] {
    seed: Row;
    if diamond {
        seed = build_diamond_cte_graph(anchor, limit);
    } else {
        seed = build_linear_cte_graph(anchor, limit);
    }
    w = seed spawn ExpandRows(limit=limit, claimed={});
    out: list[int] = sorted(w.rows);
    return out;
}

def route_recursive_query(has_recursive_cte: bool, dag_supports_recursive: bool) -> str {
    if has_recursive_cte and not dag_supports_recursive {
        return "local";
    }
    return "distributed";
}

def stage_scan_message(stage_id: str, dep_ids: list[str], has_scan_files: bool) -> str | None {
    if not dep_ids and not has_scan_files {
        return "stage " + stage_id + " has no dependencies and no ScanFiles";
    }
    return None;
}

def lookup_stage(stages: dict[str, Row], stage_id: str) -> Row | None {
    if stage_id in stages {
        return stages[stage_id];
    }
    return None;
}
