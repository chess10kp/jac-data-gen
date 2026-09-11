"""chrischeng-c4/axiom#3640 — Phase A opaque-value boundary inventory gate."""

glob SITE_KINDS = frozenset({
    "producer",
    "consumer",
    "registry",
    "classifier",
    "private_metadata",
    "python_numeric",
});
glob DISPOSITIONS = frozenset({
    "legacy_debt",
    "typed_token",
    "private_only",
    "python_numeric",
});

node Site {
    has sid: str;
}

edge Depends {}

walker DownstreamReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has known: dict[str, bool] = {};
    has site_kinds: dict[str, str] = {};
    has target_kinds: list[str] = [];
    has targets_active: bool = False;

    can step with Site entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if not (here.sid in self.known) {
            kind = self.site_kinds.get(here.sid, "");
            if not self.targets_active or (kind in self.target_kinds) {
                self.reached.append(here.sid);
            }
        }
        visit [->:Depends:->][?:Site];
    }
}

def _materialize_from_adj(adj: dict[str, list[str]]) -> dict[str, Site] {
    sites: dict[str, Site] = {};
    for sid in adj.keys() {
        nd = Site(sid=sid);
        root ++> nd;
        sites[sid] = nd;
    }
    for (src, dsts) in adj.items() {
        s = sites.get(src, None);
        if s is None { continue; }
        for dst in dsts {
            d = sites.get(dst, None);
            if d is not None { s +>:Depends:+> d; }
        }
    }
    return sites;
}

def build_flow_graph(
    site_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> dict[str, list[str]] {
    sid_set: dict[str, bool] = {};
    sites: dict[str, Site] = {};
    for s in site_ids { sid_set[s] = True; }
    for sid in site_ids {
        nd = Site(sid=sid);
        root ++> nd;
        sites[sid] = nd;
    }
    for (src, dst) in depends_edges {
        if src in sid_set and dst in sid_set {
            s = sites.get(src, None);
            d = sites.get(dst, None);
            if s is not None and d is not None { s +>:Depends:+> d; }
        }
    }
    adj: dict[str, list[str]] = {};
    for sid in site_ids {
        row: list[str] = [];
        sn = sites.get(sid, None);
        if sn is not None {
            for ch in [sn ->:Depends:->][?:Site] {
                row.append(ch.sid);
            }
        }
        adj[sid] = row;
    }
    return adj;
}

def downstream_reach(
    adj: dict[str, list[str]],
    seeds: list[str],
    *,
    site_kinds: dict[str, str] | None = None,
    target_kinds: frozenset[str] | None = None,
) -> list[str] {
    kinds = site_kinds if site_kinds is not None else {};
    targets = target_kinds if target_kinds is not None else frozenset();
    sites = _materialize_from_adj(adj);
    known: dict[str, bool] = {};
    for s in seeds {
        if s in adj { known[s] = True; }
    }
    claimed: dict[str, bool] = {};
    reached: list[str] = [];
    target_list: list[str] = [];
    for t in targets { target_list.append(t); }
    targets_active = len(target_list) > 0;
    spawned: dict[str, bool] = {};
    for seed in seeds {
        if not (seed in known) { continue; }
        if seed in spawned { continue; }
        spawned[seed] = True;
        sn = sites.get(seed, None);
        if sn is not None {
            sn spawn DownstreamReach(
                claimed=claimed,
                reached=reached,
                known=known,
                site_kinds=kinds,
                target_kinds=target_list,
                targets_active=targets_active,
            );
        }
    }
    out: list[str] = [];
    for x in reached { out.append(x); }
    return sorted(out);
}

def parent_route_chain(parent_of: dict[str, str], site: str) -> list[str] {
    chain: list[str] = [];
    cur = site;
    on_path: dict[str, bool] = {site: True};
    while cur in parent_of {
        nxt = parent_of[cur];
        if nxt in on_path { break; }
        on_path[nxt] = True;
        chain.append(nxt);
        cur = nxt;
    }
    return chain;
}

def load_ledger(
    discovered: list[str],
    rows: dict[str, dict],
) -> dict[str, dict] {
    out: dict[str, dict] = {};
    for sid in discovered {
        if sid in rows {
            copied: dict[str, any] = {};
            for (k, v) in rows[sid].items() { copied[k] = v; }
            out[sid] = copied;
        } else {
            out[sid] = {"disposition": "needs_classification"};
        }
    }
    return out;
}

def audit_inventory(
    adj: dict[str, list[str]],
    discovered: list[str],
    ledger: dict[str, dict],
    site_kinds: dict[str, str],
    *,
    mode: str = "inventory",
    stale: frozenset[str] | None = None,
    covered_files: frozenset[str] | None = None,
    source_files: list[str] | None = None,
) -> list[str] {
    stale_set = stale if stale is not None else frozenset();
    covered = covered_files if covered_files is not None else frozenset();
    files = source_files if source_files is not None else [];
    diag: list[str] = [];

    for sid in sorted(discovered) {
        row = ledger.get(sid, {});
        disp = row.get("disposition", "needs_classification");
        if disp == "needs_classification" {
            diag.append(f"unclassified:{sid}");
        }
        if sid in stale_set {
            diag.append(f"stale_row:{sid}");
        }
        kind = site_kinds.get(sid, row.get("kind", ""));
        if kind == "producer" and disp == "python_numeric" {
            diag.append(f"producer_misclassified_numeric:{sid}");
        }
        if kind == "private_metadata" and row.get("reified", False) {
            diag.append(f"private_reified:{sid}");
        }
    }

    for (sid, kind) in site_kinds.items() {
        if kind == "classifier" and sid.startswith("as_int") {
            prow = ledger.get(sid, {});
            parent_route = prow.get("parent_route", None);
            if not parent_route {
                consumers = downstream_reach(
                    adj,
                    [sid],
                    site_kinds=site_kinds,
                    target_kinds=frozenset({"consumer", "registry"}),
                );
                if len(consumers) > 0 {
                    diag.append(f"as_int_without_route:{sid}");
                }
            }
        }
    }

    for fp in sorted(files) {
        if fp not in covered {
            diag.append(f"uncovered_file:{fp}");
        }
    }

    legacy = 0;
    for sid in discovered {
        lrow = ledger.get(sid, {});
        if lrow.get("disposition", None) == "legacy_debt" {
            legacy += 1;
        }
    }
    if mode == "typed_only" and legacy > 0 {
        diag.append("legacy_debt_blocks_typed_token");
    }

    out: list[str] = [];
    for d in sorted(diag) { out.append(d); }
    return out;
}

test "diamond adversarial downstream revisit multiset" {
    ids = ["apex", "left", "right", "merge"];
    edges = [
        ("right", "merge"),
        ("apex", "left"),
        ("left", "merge"),
        ("apex", "right"),
    ];
    adj = build_flow_graph(ids, edges);
    kinds = {
        "apex": "producer",
        "left": "registry",
        "right": "classifier",
        "merge": "consumer",
    };
    assert downstream_reach(adj, ["apex"]) == ["left", "merge", "right"];;
    assert downstream_reach(adj, ["left", "right"]) == ["merge"];;
    assert downstream_reach(
        adj,
        ["apex"],
        site_kinds=kinds,
        target_kinds=frozenset({"consumer", "registry"}),
    ) == ["left", "merge"];;
}

test "cycle tail reachable claim map skip" {
    adj = build_flow_graph(
        ["a", "b", "c", "d"],
        [("b", "d"), ("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert downstream_reach(adj, ["a"]) == ["b", "c", "d"];;
    assert downstream_reach(adj, ["c"]) == ["a", "b", "d"];;
}

test "unknown id tolerance seeds and phantom edges" {
    adj = build_flow_graph(
        ["solo"],
        [("solo", "phantom"), ("phantom", "solo"), ("missing", "solo")],
    );
    assert adj == {"solo": []};;
    assert downstream_reach(adj, ["ghost"]) == [];;
    assert downstream_reach(adj, ["ghost", "nope", "solo"]) == [];;
    wide = build_flow_graph(["x", "y"], [("x", "y")]);
    assert downstream_reach(wide, ["ghost", "x"]) == ["y"];;
}

test "as_int classifier isolated without route silent" {
    adj = build_flow_graph(["as_int_orphan", "dead_end"], []);
    ledger = {
        "as_int_orphan": {
            "kind": "classifier",
            "disposition": "typed_token",
            "family": "LonelyBridge",
        },
        "dead_end": {"kind": "producer", "disposition": "legacy_debt"},
    };
    kinds = {
        "as_int_orphan": "classifier",
        "dead_end": "producer",
    };
    assert audit_inventory(
        adj,
        ["as_int_orphan", "dead_end"],
        ledger,
        kinds,
        mode="typed_only",
    ) == ["legacy_debt_blocks_typed_token"];;
    assert audit_inventory(
        adj,
        ["as_int_orphan", "dead_end"],
        ledger,
        kinds,
        mode="inventory",
    ) == [];;
}

test "parent_route_chain mid cycle entry stops at revisit" {
    loop = {"x": "y", "y": "z", "z": "x"};
    assert parent_route_chain(loop, "y") == ["z", "x"];;
    assert parent_route_chain({"solo": "solo"}, "solo") == [];;
    assert parent_route_chain({}, "any") == [];;
}

test "load_ledger copies rows independently of source mutation" {
    rows = {
        "keep": {"disposition": "typed_token", "kind": "consumer"},
        "touch": {"disposition": "private_only", "reified": False},
    };
    ledger = load_ledger(["keep", "touch", "absent"], rows);
    rows["keep"]["disposition"] = "legacy_debt";
    rows["touch"]["reified"] = True;
    assert ledger["keep"]["disposition"] == "typed_token";;
    assert ledger["touch"]["reified"] == False;;
    assert ledger["absent"] == {"disposition": "needs_classification"};;
}
