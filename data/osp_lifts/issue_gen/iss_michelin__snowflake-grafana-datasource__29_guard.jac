"""michelin/snowflake-grafana-datasource#29 — recursive downstream run closure + s3 aggregation."""

node Run {
    has run_id: str;
    has job_name: str = "";
    has started: int = 0;
    has completed: int = 0;
    has pr: str = "";
    has pr_create: str = "";
}

node GraphRoot {
    has run_index: dict[str, Run] = {};
}

edge Downstream {}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can descend with Run entry {
        if here.run_id in self.claimed { skip; }
        self.claimed[here.run_id] = True;
        self.found.append(here.run_id);
        print(here.run_id);
        kids: list[Run] = [here ->:Downstream:->][?:Run];
        if kids {
            for kid in kids {
                visit :0: kid;
            }
        }
    }
}

def build_run_graph(runs: list[dict], premerge_rows: list[dict]) -> GraphRoot {
    g = GraphRoot();
    root ++> g;
    idx: dict[str, Run] = {};
    for rd in runs {
        rid = rd["run_id"];
        nd = Run(
            run_id=rid,
            job_name=rd["job_name"],
            started=rd["started"],
            completed=rd["completed"],
        );
        idx[rid] = nd;
        g ++> nd;
    }
    g.run_index = idx;
    for pm in premerge_rows {
        pr_run = pm["run_id"];
        if pr_run in idx {
            idx[pr_run].pr = pm["pr"];
            idx[pr_run].pr_create = pm["created_at"];
        }
    }
    for rd in runs {
        up = rd["upstream_run_id"];
        if up is None { continue; }
        if up not in idx { continue; }
        par = idx[up];
        ch = idx[rd["run_id"]];
        par +>:Downstream:+> ch;
    }
    return g;
}

def filter_seed_run_ids(premerge_rows: list[dict], time_lo: str, time_hi: str) -> list[str] {
    out: list[str] = [];
    for row in premerge_rows {
        rid = row["run_id"];
        if rid is None { continue; }
        ts = row["created_at"];
        if ts > time_lo and ts < time_hi {
            out.append(rid);
        }
    }
    return sorted(out);
}

def recursive_run_closure(g: GraphRoot, seed_run_ids: list[str]) -> list[str] {
    claimed: dict[str, bool] = {};
    found: list[str] = [];
    for sid in seed_run_ids {
        if sid not in g.run_index { continue; }
        nd = g.run_index[sid];
        w = nd spawn ClosureWalker(claimed=claimed);
        for rid in w.found {
            found.append(rid);
        }
    }
    uniq: dict[str, bool] = {};
    out: list[str] = [];
    for rid in found {
        if rid not in uniq {
            uniq[rid] = True;
            out.append(rid);
        }
    }
    return sorted(out);
}

def s3_machine_time_by_pr_time(g: GraphRoot, run_ids: list[str]) -> list[tuple[str, str, float]] {
    totals: dict[str, float] = {};
    keys_seen: dict[str, bool] = {};
    for rid in run_ids {
        if rid not in g.run_index { continue; }
        r = g.run_index[rid];
        if not r.job_name.startswith("s3_") { continue; }
        k = r.pr + "|" + r.pr_create;
        keys_seen[k] = True;
        if k not in totals { totals[k] = 0.0; }
        totals[k] = totals[k] + (r.completed - r.started);
    }
    out: list[tuple[str, str, float]] = [];
    ks: list[str] = sorted(keys_seen);
    for k in ks {
        parts: list[str] = k.split("|");
        out.append((parts[0], parts[1], totals[k]));
    }
    return out;
}

test "diamond_revisit_claimed_once" {
    runs: list[dict] = [
        {"run_id": "A", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": None},
        {"run_id": "B", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": "A"},
        {"run_id": "C", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": "A"},
        {"run_id": "D", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": "B"},
        {"run_id": "D", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": "C"},
    ];
    g = build_run_graph(runs, []);
    nd = g.run_index["A"];
    w = nd spawn ClosureWalker(claimed={});
    ids = w.found;
    assert sorted(ids) == ["A", "B", "C", "D"];
    assert ids.count("D") == 1;
}

test "closure_sorted_api" {
    runs: list[dict] = [
        {"run_id": "A", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": None},
        {"run_id": "B", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": "A"},
        {"run_id": "C", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": "A"},
        {"run_id": "D", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": "B"},
        {"run_id": "D", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": "C"},
    ];
    g = build_run_graph(runs, []);
    got = recursive_run_closure(g, ["A"]);
    assert got == ["A", "B", "C", "D"];
}

test "s3_machine_time_grouped_sorted" {
    runs: list[dict] = [
        {"run_id": "A", "job_name": "root", "started": 0, "completed": 1, "upstream_run_id": None},
        {"run_id": "S1", "job_name": "s3_copy", "started": 100, "completed": 130, "upstream_run_id": "A"},
    ];
    premerge: list[dict] = [
        {"run_id": "A", "pr": "42", "created_at": "2022-10-11T11:00:00Z"},
        {"run_id": "S1", "pr": "42", "created_at": "2022-10-11T12:00:00Z"},
    ];
    g = build_run_graph(runs, premerge);
    seeds = filter_seed_run_ids(premerge, "2022-10-11T11:30:00Z", "2022-10-11T12:30:00Z");
    closure = recursive_run_closure(g, seeds);
    rows = s3_machine_time_by_pr_time(g, closure);
    assert rows == [("42", "2022-10-11T12:00:00Z", 30.0)];
}

test "filter_seed_run_ids_sorted" {
    premerge: list[dict] = [
        {"run_id": "Z", "pr": "1", "created_at": "2022-10-11T12:00:00Z"},
        {"run_id": "A", "pr": "2", "created_at": "2022-10-11T12:00:00Z"},
    ];
    got = filter_seed_run_ids(premerge, "2022-10-11T11:00:00Z", "2022-10-11T13:00:00Z");
    assert got == ["A", "Z"];
}

test "unknown_seed_skipped" {
    runs: list[dict] = [
        {"run_id": "A", "job_name": "j", "started": 0, "completed": 1, "upstream_run_id": None},
    ];
    g = build_run_graph(runs, []);
    got = recursive_run_closure(g, ["MISSING", "A"]);
    assert got == ["A"];
}
