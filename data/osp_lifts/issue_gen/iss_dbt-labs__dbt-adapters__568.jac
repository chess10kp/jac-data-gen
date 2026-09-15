# iss_dbt-labs__dbt-adapters__568.jac
# dbt-labs/dbt-adapters#568 — recursive CTE unit-test shell nesting vs top-level closure.

node Vert {
    has cid: str;
    has val: int = 0;
}

edge Recurse {}

walker Closer {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can expand with Vert entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print("visit " + here.cid);
        kids: list[Vert] = [];
        for ch in [here ->:Recurse:->][?:Vert] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def build_graph(edges: list[tuple[str, str]]) -> dict[str, Vert] {
    store: dict[str, Vert] = {};
    for pair in edges {
        src_id = pair[0];
        dst_id = pair[1];
        if src_id not in store {
            src_nd = Vert(cid=src_id);
            root ++> src_nd;
            store[src_id] = src_nd;
        }
        if dst_id not in store {
            dst_nd = Vert(cid=dst_id);
            root ++> dst_nd;
            store[dst_id] = dst_nd;
        }
        src_nd = store[src_id] as Vert;
        dst_nd = store[dst_id] as Vert;
        src_nd +>:Recurse:+> dst_nd;
    }
    return store;
}

def recursive_closure(store: dict[str, Vert], seed_ids: list[str]) -> list[str] {
    out: list[str] = [];
    for sid in seed_ids {
        if sid not in store {
            continue;
        }
        seed_nd = store[sid] as Vert;
        w = seed_nd spawn Closer(claimed={}, found=[]);
        for cid in w.found {
            out.append(cid);
        }
    }
    out = sorted(out);
    return out;
}

def build_unit_test_shell(fixture_tag: str, model_tag: str) -> dict[str, str] {
    body = "select * from (\n  WITH RECURSIVE\n __dbt__cte__" + fixture_tag + " as (\nselect 1 as x\n), " + model_tag + " AS (\n    SELECT *\n    FROM __dbt__cte__" + fixture_tag + "\n)\nSELECT *\nFROM " + model_tag + "\n    ) as __dbt_sbq\n    where false";
    shell: dict[str, str] = {};
    shell["body"] = body;
    shell["mode"] = "nested_subquery";
    return shell;
}

def is_valid_top_level_recursive(shell: dict[str, str]) -> bool {
    body = shell["body"];
    if "select * from (\n  WITH RECURSIVE" in body {
        return False;
    }
    if body.startswith("WITH RECURSIVE") {
        return True;
    }
    return False;
}

def unwrap_recursive_shell(shell: dict[str, str]) -> dict[str, str] {
    body = shell["body"];
    fixed = body.replace("select * from (\n  WITH RECURSIVE", "WITH RECURSIVE");
    fixed = fixed.replace("\n    ) as __dbt_sbq\n    where false", "");
    out: dict[str, str] = {};
    out["body"] = fixed;
    out["mode"] = "top_level";
    return out;
}
