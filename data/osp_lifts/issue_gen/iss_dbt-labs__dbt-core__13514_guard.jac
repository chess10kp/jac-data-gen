"""dbt-labs/dbt-core#13514 — static analysis for recursive CTE models."""

node Cte {
    has name: str;
    has recursive: bool = False;
}

edge Depends {}

node CteModel {
    has anchor: Cte | None = None;
    has unknown_refs: list[str] = [];
    has index: dict[str, Cte] = {};
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];

    can walk with Cte entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.collected.append(here.name);
        print("reach", here.name);
        kids: list[Cte] = [];
        for dep in [here ->:Depends:->][?:Cte] {
            kids.append(dep);
        }
        if kids {
            visit :0: kids;
        }
    }
}

def build_cte_model(specs: list) -> CteModel {
    model = CteModel();
    if not specs {
        return model;
    }
    for spec in specs {
        nm = spec["name"] as str;
        rec = spec["recursive"] as bool;
        nd = Cte(name=nm, recursive=rec);
        model.index[nm] = nd;
        root ++> nd;
    }
    for spec in specs {
        src_name = spec["name"] as str;
        src = model.index[src_name];
        refs = spec["refs"] as list;
        for ref_name in refs {
            rn = ref_name as str;
            if rn in model.index {
                dst = model.index[rn];
                src +>:Depends:+> dst;
            } else {
                model.unknown_refs.append(rn);
            }
        }
    }
    first = specs[0]["name"] as str;
    model.anchor = model.index[first];
    return model;
}

def cte_is_recursive(model: CteModel, name: str) -> bool {
    if name not in model.index {
        return False;
    }
    return model.index[name].recursive;
}

def reachable_ctes(model: CteModel, from_name: str) -> list[str] {
    if from_name not in model.index {
        return [];
    }
    start = model.index[from_name];
    w = start spawn ReachWalker(claimed={}, collected=[]);
    out: list[str] = [];
    for nm in w.collected {
        if nm != from_name {
            out.append(nm);
        }
    }
    return sorted(out);
}

def validate_recursive_ctes(model: CteModel) -> list[str] {
    errors: list[str] = [];
    unk_names: list[str] = [];
    for u in model.unknown_refs {
        unk_names.append(u);
    }
    for unk in sorted(unk_names) {
        errors.append("unknown cte ref " + unk);
    }
    idx_names: list[str] = [];
    for k in model.index {
        idx_names.append(k);
    }
    for nm in sorted(idx_names) {
        nd = model.index[nm];
        if nd.recursive {
            deps: list[Cte] = [];
            for dep in [nd ->:Depends:->][?:Cte] {
                deps.append(dep);
            }
            if not deps {
                errors.append("recursive cte " + nm + " missing recursive member");
            }
        }
    }
    return sorted(errors);
}

def fusion_compiles(model: CteModel) -> bool {
    return len(validate_recursive_ctes(model)) == 0;
}

test "diamond_revisit_adversarial" {
    specs: list = [
        {"name": "b", "refs": ["d"], "recursive": False},
        {"name": "d", "refs": [], "recursive": False},
        {"name": "c", "refs": ["d"], "recursive": False},
        {"name": "a", "refs": ["b", "c"], "recursive": False},
    ];
    m = build_cte_model(specs);
    assert reachable_ctes(m, "a") == ["b", "c", "d"];
}

test "reachable_simple_chain" {
    specs: list = [
        {"name": "x", "refs": ["y"], "recursive": False},
        {"name": "y", "refs": ["z"], "recursive": False},
        {"name": "z", "refs": [], "recursive": False},
    ];
    m = build_cte_model(specs);
    assert reachable_ctes(m, "x") == ["y", "z"];
    assert reachable_ctes(m, "missing") == [];
}

test "unknown_ref_errors" {
    specs: list = [
        {"name": "m", "refs": ["ghost"], "recursive": False},
    ];
    m = build_cte_model(specs);
    assert validate_recursive_ctes(m) == ["unknown cte ref ghost"];
    assert fusion_compiles(m) == False;
}

test "recursive_missing_member" {
    specs: list = [
        {"name": "r", "refs": [], "recursive": True},
    ];
    m = build_cte_model(specs);
    assert validate_recursive_ctes(m) == ["recursive cte r missing recursive member"];
    assert cte_is_recursive(m, "r") == True;
}

test "fusion_compiles_ok" {
    specs: list = [
        {"name": "base", "refs": [], "recursive": False},
        {"name": "rec", "refs": ["base"], "recursive": True},
    ];
    m = build_cte_model(specs);
    assert validate_recursive_ctes(m) == [];
    assert fusion_compiles(m) == True;
}

test "reachable_excludes_start" {
    specs: list = [
        {"name": "solo", "refs": [], "recursive": False},
    ];
    m = build_cte_model(specs);
    assert reachable_ctes(m, "solo") == [];
}
