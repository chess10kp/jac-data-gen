"""tdupu/gascity#52 — workflow root descendant counting (two-phase vs recursive CTE)."""

node Wisp {
    has wisp_id: str;
    has kind: str = "";
    has formula_contract: str = "";
    has root_bead_id: str = "";
}

edge ChildLink {}

walker CountDesc {
    has claimed: dict[str, bool] = {};
    has tally: int = 0;

    can step with Wisp entry {
        if here.wisp_id in self.claimed {
            skip;
        }
        self.claimed[here.wisp_id] = True;
        self.tally = self.tally + 1;
        kids: list[Wisp] = [here ->:ChildLink:->][?:Wisp];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

def make_wisp(wid: str, kind: str, contract: str, bead: str) -> Wisp {
    w = Wisp(wisp_id=wid, kind=kind, formula_contract=contract, root_bead_id=bead);
    root ++> w;
    return w;
}

def wire_wisps(wisps: list[Wisp]) -> None {
    by_id: dict[str, Wisp] = {};
    for w in wisps {
        by_id[w.wisp_id] = w;
    }
    for w in wisps {
        if w.root_bead_id != "" && w.root_bead_id != w.wisp_id {
            if w.root_bead_id in by_id {
                par = by_id[w.root_bead_id];
                par +>:ChildLink:+> w;
            }
        }
    }
}

def is_workflow_root(w: Wisp) -> bool {
    if w.kind != "workflow_issue" {
        return False;
    }
    if w.formula_contract != "inactive" {
        return False;
    }
    if w.root_bead_id != "" && w.root_bead_id != w.wisp_id {
        return False;
    }
    return True;
}

def find_workflow_roots(wisps: list[Wisp]) -> list[str] {
    out: list[str] = [];
    for w in wisps {
        if is_workflow_root(w) {
            out.append(w.wisp_id);
        }
    }
    return sorted(out);
}

def count_descendants_recursive(root_id: str, wisps: list[Wisp]) -> int {
    by_id: dict[str, Wisp] = {};
    for w in wisps {
        by_id[w.wisp_id] = w;
    }
    if root_id not in by_id {
        return 0;
    }
    graph_root = by_id[root_id];
    wk = graph_root spawn CountDesc(claimed={});
    return wk.tally;
}

def count_descendants_two_phase(root_ids: list[str], wisps: list[Wisp]) -> dict[str, int] {
    by_id: dict[str, Wisp] = {};
    for w in wisps {
        by_id[w.wisp_id] = w;
    }
    out: dict[str, int] = {};
    ordered: list[str] = sorted(root_ids);
    for rid in ordered {
        if rid not in by_id {
            out[rid] = 0;
        } else {
            seen: dict[str, bool] = {};
            frontier: list[str] = [rid];
            seen[rid] = True;
            idx = 0;
            while idx < len(frontier) {
                cur = frontier[idx];
                idx = idx + 1;
                for w in wisps {
                    if w.root_bead_id == cur && w.wisp_id != cur && w.wisp_id not in seen {
                        seen[w.wisp_id] = True;
                        frontier.append(w.wisp_id);
                    }
                }
            }
            out[rid] = len(seen);
        }
    }
    return out;
}

def workflow_root_counts(wisps: list[Wisp]) -> dict[str, int] {
    roots = find_workflow_roots(wisps);
    return count_descendants_two_phase(roots, wisps);
}

with entry {
    demo_root = make_wisp("demo_root", "workflow_issue", "inactive", "demo_root");
    demo_c1 = make_wisp("demo_c1", "wisp", "", "demo_root");
    demo_c2 = make_wisp("demo_c2", "wisp", "", "demo_c1");
    wire_wisps([demo_root, demo_c1, demo_c2]);
    wk = demo_root spawn CountDesc(claimed={});
    print({"demo_root_descendants": wk.tally});
}
