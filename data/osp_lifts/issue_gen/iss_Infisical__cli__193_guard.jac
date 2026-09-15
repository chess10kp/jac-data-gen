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

test "recursive_export_nested" {
    graph_root = Folder(cid="proj", name="root");
    root ++> graph_root;
    sub = Folder(cid="sub", name="sub");
    leaf = Folder(cid="leaf", name="leaf");
    graph_root +>:Contains:+> sub;
    sub +>:Contains:+> leaf;
    e_root = Env(key="A", value="1");
    graph_root +>:HasEnv:+> e_root;
    e_sub = Env(key="B", value="2");
    sub +>:HasEnv:+> e_sub;
    e_leaf = Env(key="C", value="3");
    leaf +>:HasEnv:+> e_leaf;
    got = export_envs_recursive(graph_root, "proj");
    assert len(got) == 3;
    assert got[0]["folder_id"] == "leaf";
    assert got[0]["key"] == "C";
    assert got[1]["folder_id"] == "proj";
    assert got[1]["key"] == "A";
    assert got[2]["folder_id"] == "sub";
    assert got[2]["key"] == "B";
}

test "diamond_revisit_collects_once" {
    graph_root = Folder(cid="proj", name="root");
    root ++> graph_root;
    left = Folder(cid="left", name="left");
    right = Folder(cid="right", name="right");
    mid = Folder(cid="mid", name="mid");
    graph_root +>:Contains:+> left;
    graph_root +>:Contains:+> right;
    left +>:Contains:+> mid;
    right +>:Contains:+> mid;
    ev = Env(key="SHARED", value="secret");
    mid +>:HasEnv:+> ev;
    got = export_envs_recursive(graph_root, "proj");
    assert len(got) == 1;
    assert got[0]["folder_id"] == "mid";
    assert got[0]["key"] == "SHARED";
}

test "unknown_folder_id_empty" {
    graph_root = Folder(cid="only", name="solo");
    root ++> graph_root;
    ev = Env(key="X", value="y");
    graph_root +>:HasEnv:+> ev;
    got = export_envs_recursive(graph_root, "missing");
    assert len(got) == 0;
}

test "folder_without_envs" {
    graph_root = Folder(cid="proj", name="root");
    root ++> graph_root;
    sub = Folder(cid="sub", name="sub");
    graph_root +>:Contains:+> sub;
    got = export_envs_recursive(graph_root, "proj");
    assert len(got) == 0;
}

test "cycle_skips_revisit" {
    graph_root = Folder(cid="a", name="a");
    root ++> graph_root;
    b = Folder(cid="b", name="b");
    graph_root +>:Contains:+> b;
    b +>:Contains:+> graph_root;
    e_a = Env(key="KA", value="va");
    graph_root +>:HasEnv:+> e_a;
    e_b = Env(key="KB", value="vb");
    b +>:HasEnv:+> e_b;
    got = export_envs_recursive(graph_root, "a");
    assert len(got) == 2;
    assert got[0]["folder_id"] == "a";
    assert got[0]["key"] == "KA";
    assert got[1]["folder_id"] == "b";
    assert got[1]["key"] == "KB";
}
