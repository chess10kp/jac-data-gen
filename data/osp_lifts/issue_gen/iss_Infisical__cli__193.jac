"""Infisical/cli#193 — recursive env export across folder tree."""

node Folder {
    has cid: str;
    has name: str;
}

node Env {
    has key: str;
    has value: str;
}

edge Contains {}

edge HasEnv {}

walker CollectEnvs {
    has claimed: dict[str, bool] = {};
    has rows: list[dict[str, str]] = [];
    has root_id: str = "";

    can step with Folder entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("scan", here.cid);
        for ev in [here ->:HasEnv:->][?:Env] {
            row: dict[str, str] = {};
            row["folder_id"] = here.cid;
            row["key"] = ev.key;
            row["value"] = ev.value;
            self.rows.append(row);
        }
        kids: list[Folder] = [];
        for ch in [here ->:Contains:->][?:Folder] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
    }
}

def find_folder(graph_root: Folder, cid: str) -> Folder | None {
    if graph_root.cid == cid {
        return graph_root;
    }
    for ch in [graph_root ->:Contains:->][?:Folder] {
        hit = find_folder(ch, cid);
        if hit is not None {
            return hit;
        }
    }
    return None;
}

def sort_env_rows(rows: list[dict[str, str]]) -> list[dict[str, str]] {
    keys: list[str] = [];
    for r in rows {
        keys.append(r["folder_id"] + "|" + r["key"]);
    }
    keys.sort();
    out: list[dict[str, str]] = [];
    for k in keys {
        for r in rows {
            tag = r["folder_id"] + "|" + r["key"];
            if tag == k {
                out.append(r);
                break;
            }
        }
    }
    return out;
}

def export_envs_recursive(graph_root: Folder, folder_id: str) -> list[dict[str, str]] {
    start = find_folder(graph_root, folder_id);
    if start is None {
        return [];
    }
    w = start spawn CollectEnvs(claimed={}, rows=[], root_id=folder_id);
    return sort_env_rows(w.rows);
}

def build_demo_graph -> Folder {
    graph_root = Folder(cid="proj", name="root");
    ops = Folder(cid="ops", name="ops");
    dev = Folder(cid="dev", name="dev");
    graph_root +>:Contains:+> ops;
    graph_root +>:Contains:+> dev;
    e0 = Env(key="ROOT_TOKEN", value="r0");
    graph_root +>:HasEnv:+> e0;
    e1 = Env(key="OPS_DB", value="postgres://ops");
    ops +>:HasEnv:+> e1;
    e2 = Env(key="DEV_DB", value="postgres://dev");
    dev +>:HasEnv:+> e2;
    return graph_root;
}

with entry {
    demo_root = build_demo_graph();
    root ++> demo_root;
    rows = export_envs_recursive(demo_root, "proj");
    print(len(rows));
}
