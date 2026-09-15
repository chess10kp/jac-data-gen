# dimagi/django-cte#66 — recursive region rootmap and order totals (CTE lift)

node Region {
    has cid: str;
    has name: str;
    has parent_id: str | None = None;
}

node GraphAnchor {
    has aid: str = "g";
}

edge AnchorLink {}
edge Child {}

walker RootMapWalker {
    has claimed: dict[str, bool] = {};
    has mapping: dict[str, str] = {};

    can anchor_entry with GraphAnchor entry {
        print(["rootmap", "seed"]);
        seeds: list[Region] = [];
        for reg in [here ->:AnchorLink:->][?:Region] {
            if reg.parent_id is None {
                self.mapping[reg.name] = reg.name;
                seeds.append(reg);
            }
        }
        for s in seeds {
            visit :0: [s];
        }
    }

    can region_step with Region entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(["rootmap", here.name, self.mapping[here.name]]);
        root_val: str = self.mapping[here.name];
        kids: list[Region] = [];
        for ch in [here ->:Child:->][?:Region] {
            if ch.name not in self.mapping {
                self.mapping[ch.name] = root_val;
            }
            kids.append(ch);
        }
        for kid in kids {
            visit :0: [kid];
        }
    }
}

def _build_graph(regions: list) -> GraphAnchor {
    anchor = GraphAnchor();
    root ++> anchor;
    by_name: dict[str, Region] = {};
    for row in regions {
        r = row as dict;
        nm: str = r["name"] as str;
        pid: str | None = None;
        if "parent_id" in r {
            if r["parent_id"] is not None {
                pid = r["parent_id"] as str;
            }
        }
        nd = Region(cid=nm, name=nm, parent_id=pid);
        by_name[nm] = nd;
        anchor +>:AnchorLink:+> nd;
    }
    nms: list[str] = sorted(by_name.keys());
    for nm in nms {
        nd = by_name[nm];
        if nd.parent_id is not None {
            if nd.parent_id in by_name {
                par = by_name[nd.parent_id];
                par +>:Child:+> nd;
            }
        }
    }
    return anchor;
}

def rootmap_for_regions(regions: list) -> dict[str, str] {
    anchor = _build_graph(regions);
    wk = anchor spawn RootMapWalker(claimed={}, mapping={});
    print(wk.mapping);
    return wk.mapping;
}

def totals_for_orders(regions: list, orders: list) -> dict[str, dict[str, int]] {
    mapping = rootmap_for_regions(regions);
    totals: dict[str, dict[str, int]] = {};
    for ord_row in orders {
        od = ord_row as dict;
        rid: str = od["region_id"] as str;
        amt: int = od["amount"] as int;
        if rid not in mapping {
            continue;
        }
        rt: str = mapping[rid];
        if rt not in totals {
            totals[rt] = {"orders_count": 0, "region_total": 0};
        }
        bucket = totals[rt] as dict[str, int];
        bucket["orders_count"] = bucket["orders_count"] + 1;
        bucket["region_total"] = bucket["region_total"] + amt;
    }
    return totals;
}

def region_rows(regions: list, orders: list) -> list[tuple] {
    mapping = rootmap_for_regions(regions);
    totals = totals_for_orders(regions, orders);
    rows: list[tuple] = [];
    for row in regions {
        r = row as dict;
        nm: str = r["name"] as str;
        pid: str | None = None;
        if "parent_id" in r {
            if r["parent_id"] is not None {
                pid = r["parent_id"] as str;
            }
        }
        oc: int = 0;
        rg: int = 0;
        if nm in mapping {
            rt: str = mapping[nm];
            if rt in totals {
                tb = totals[rt] as dict[str, int];
                oc = tb["orders_count"];
                rg = tb["region_total"];
            }
        }
        rows.append((nm, pid, oc, rg));
    }
    out: list[tuple] = sorted(rows);
    return out;
}

test "adversarial_reverse_region_order" {
    regions = [
        {"name": "d", "parent_id": "c"},
        {"name": "c", "parent_id": "b"},
        {"name": "b", "parent_id": "a"},
        {"name": "a", "parent_id": None},
    ];
    m = rootmap_for_regions(regions);
    assert (m == {"a": "a", "b": "a", "c": "a", "d": "a"});
}

test "recursive_root_totals_shared" {
    regions = [
        {"name": "west", "parent_id": None},
        {"name": "ca", "parent_id": "west"},
        {"name": "sf", "parent_id": "ca"},
    ];
    orders = [
        {"region_id": "sf", "amount": 10},
        {"region_id": "ca", "amount": 20},
    ];
    rows = region_rows(regions, orders);
    assert (rows == [
        ("ca", "west", 2, 30),
        ("sf", "ca", 2, 30),
        ("west", None, 2, 30),
    ]);
}

test "unknown_parent_orphan_excluded" {
    regions = [{"name": "x", "parent_id": "ghost"}];
    m = rootmap_for_regions(regions);
    assert (m == {});
    rows = region_rows(regions, [{"region_id": "x", "amount": 9}]);
    assert (rows == [("x", "ghost", 0, 0)]);
}

test "unknown_order_region_skipped" {
    regions = [{"name": "r", "parent_id": None}];
    totals = totals_for_orders(regions, [{"region_id": "nope", "amount": 5}]);
    assert (totals == {});
}

test "multi_root_sorted_rows" {
    regions = [
        {"name": "east", "parent_id": None},
        {"name": "west", "parent_id": None},
        {"name": "nyc", "parent_id": "east"},
    ];
    orders = [
        {"region_id": "nyc", "amount": 7},
        {"region_id": "west", "amount": 3},
    ];
    rows = region_rows(regions, orders);
    assert (rows == [
        ("east", None, 1, 7),
        ("nyc", "east", 1, 7),
        ("west", None, 1, 3),
    ]);
}
