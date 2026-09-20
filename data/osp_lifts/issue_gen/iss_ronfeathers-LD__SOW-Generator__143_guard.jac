"""ronfeathers-LD/SOW-Generator#143 — folder tree traversal lift."""

glob MAX_DEPTH_DEFAULT = 3;

node Folder {
    has fid: str;
    has name: str;
}

edge Child {}

obj DriveFS {
    has anchor: Folder;
    has by_id: dict[str, Folder];
}

walker StructureWalker {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 3;
    has rows: list[dict[str, any]] = [];
    has cur_depth: int = 0;

    can step with Folder entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        row: dict[str, any] = {};
        row["id"] = here.fid;
        row["name"] = here.name;
        row["depth"] = self.cur_depth;
        self.rows.append(row);
        print ["structure", here.fid, self.cur_depth];
        if self.cur_depth < self.max_depth {
            kids: list[Folder] = [];
            for ch in [here ->:Child:->][?:Folder] {
                kids.append(ch);
            }
            fids: list[str] = [];
            for k in kids {
                fids.append(k.fid);
            }
            fids = sorted(fids);
            ordered: list[Folder] = [];
            for fid in fids {
                for k in kids {
                    if k.fid == fid {
                        ordered.append(k);
                    }
                }
            }
            next_d = self.cur_depth + 1;
            for tgt in ordered {
                tgt spawn StructureWalker(
                    claimed=self.claimed,
                    max_depth=self.max_depth,
                    rows=self.rows,
                    cur_depth=next_d
                );
            }
        }
        disengage;
    }
}

def new_drive_fs -> DriveFS {
    fs = DriveFS();
    fs.anchor = Folder(fid="__anchor__", name="anchor");
    idx: dict[str, Folder] = {};
    fs.by_id = idx;
    return fs;
}

def build_drive_fs(entries: list[dict[str, any]]) -> DriveFS {
    fs = new_drive_fs();
    for ent in entries {
        nd = Folder(fid=ent["id"], name=ent["name"]);
        fs.anchor ++> nd;
        fs.by_id[ent["id"]] = nd;
    }
    for ent in entries {
        if "parent_id" in ent and ent["parent_id"] is not None {
            pid = ent["parent_id"];
            cid = ent["id"];
            if pid in fs.by_id and cid in fs.by_id {
                par = fs.by_id[pid];
                ch = fs.by_id[cid];
                par +>:Child:+> ch;
            }
        }
    }
    return fs;
}

def sort_rows_by_id(rows: list[dict[str, any]]) -> list[dict[str, any]] {
    ids: list[str] = [];
    for r in rows {
        ids.append(r["id"]);
    }
    ids = sorted(ids);
    out: list[dict[str, any]] = [];
    for i in ids {
        for r in rows {
            if r["id"] == i {
                out.append(r);
            }
        }
    }
    return out;
}

def parent_name_of(fs: DriveFS, fid: str) -> str {
    if fid not in fs.by_id {
        return "";
    }
    nd = fs.by_id[fid];
    parents: list[Folder] = [];
    for p in [nd <-:Child:<-][?:Folder] {
        parents.append(p);
    }
    if len(parents) == 0 {
        return "";
    }
    p0 = parents[0];
    if p0.fid == "__anchor__" {
        return "";
    }
    return p0.name;
}

def memo_parent_names(fs: DriveFS) -> dict[str, str] {
    cache: dict[str, str] = {};
    keys: list[str] = [];
    for k in fs.by_id {
        keys.append(k);
    }
    keys = sorted(keys);
    for fid in keys {
        cache[fid] = parent_name_of(fs, fid);
    }
    return cache;
}

def get_folder_structure(fs: DriveFS, root_id: str, max_depth: int = 3) -> list[dict[str, any]] {
    if root_id not in fs.by_id {
        return [];
    }
    start = fs.by_id[root_id];
    w = start spawn StructureWalker(max_depth=max_depth);
    return sort_rows_by_id(w.rows);
}

def get_folder_contents(fs: DriveFS, folder_id: str) -> dict[str, any] {
    empty: dict[str, any] = {};
    empty["folder_id"] = folder_id;
    empty["name"] = "";
    empty["parent_name"] = "";
    empty["subfolders"] = [];
    if folder_id not in fs.by_id {
        return empty;
    }
    nd = fs.by_id[folder_id];
    names = memo_parent_names(fs);
    subs: list[str] = [];
    for ch in [nd ->:Child:->][?:Folder] {
        subs.append(ch.fid);
    }
    subs = sorted(subs);
    out: dict[str, any] = {};
    out["folder_id"] = folder_id;
    out["name"] = nd.name;
    if folder_id in names {
        out["parent_name"] = names[folder_id];
    } else {
        out["parent_name"] = "";
    }
    out["subfolders"] = subs;
    return out;
}

test "unknown_root_structure_empty" {
    fs = new_drive_fs();
    rows = get_folder_structure(fs, "missing", 3);
    assert len(rows) == 0;;
}

test "structure_depth_and_sort" {
    entries: list[dict[str, any]] = [];
    e1: dict[str, any] = {};
    e1["id"] = "a";
    e1["name"] = "A";
    entries.append(e1);
    e2: dict[str, any] = {};
    e2["id"] = "b";
    e2["name"] = "B";
    e2["parent_id"] = "a";
    entries.append(e2);
    e3: dict[str, any] = {};
    e3["id"] = "c";
    e3["name"] = "C";
    e3["parent_id"] = "b";
    entries.append(e3);
    fs = build_drive_fs(entries);
    rows = get_folder_structure(fs, "a", 2);
    assert len(rows) == 3;;
    assert rows[0]["id"] == "a";;
    assert rows[0]["depth"] == 0;;
    assert rows[1]["id"] == "b";;
    assert rows[1]["depth"] == 1;;
    assert rows[2]["id"] == "c";;
    assert rows[2]["depth"] == 2;;
}

test "contents_missing_folder" {
    fs = new_drive_fs();
    out = get_folder_contents(fs, "nope");
    assert out["folder_id"] == "nope";;
    assert out["name"] == "";;
    assert out["parent_name"] == "";;
    assert len(out["subfolders"]) == 0;;
}

test "contents_parent_and_subfolders_sorted" {
    entries: list[dict[str, any]] = [];
    r: dict[str, any] = {};
    r["id"] = "r";
    r["name"] = "Root";
    entries.append(r);
    z: dict[str, any] = {};
    z["id"] = "z";
    z["name"] = "Zed";
    z["parent_id"] = "r";
    entries.append(z);
    m: dict[str, any] = {};
    m["id"] = "m";
    m["name"] = "Mid";
    m["parent_id"] = "r";
    entries.append(m);
    fs = build_drive_fs(entries);
    out = get_folder_contents(fs, "m");
    assert out["folder_id"] == "m";;
    assert out["name"] == "Mid";;
    assert out["parent_name"] == "Root";;
    assert out["subfolders"] == [];;
    root_out = get_folder_contents(fs, "r");
    assert root_out["subfolders"] == ["m", "z"];;
}

test "diamond_cycle_claim_once" {
    entries: list[dict[str, any]] = [];
    a: dict[str, any] = {};
    a["id"] = "a";
    a["name"] = "A";
    entries.append(a);
    b: dict[str, any] = {};
    b["id"] = "b";
    b["name"] = "B";
    b["parent_id"] = "a";
    entries.append(b);
    c: dict[str, any] = {};
    c["id"] = "c";
    c["name"] = "C";
    c["parent_id"] = "a";
    entries.append(c);
    d: dict[str, any] = {};
    d["id"] = "d";
    d["name"] = "D";
    d["parent_id"] = "b";
    entries.append(d);
    d2: dict[str, any] = {};
    d2["id"] = "d";
    d2["name"] = "D";
    d2["parent_id"] = "c";
    entries.append(d2);
    fs = build_drive_fs(entries);
    rows = get_folder_structure(fs, "a", 5);
    ids: list[str] = [];
    for r in rows {
        ids.append(r["id"]);
    }
    assert ids == ["a", "b", "c", "d"];;
}

test "memo_parent_names_sorted_keys" {
    entries: list[dict[str, any]] = [];
    p: dict[str, any] = {};
    p["id"] = "p";
    p["name"] = "Par";
    entries.append(p);
    ch: dict[str, any] = {};
    ch["id"] = "x";
    ch["name"] = "Chi";
    ch["parent_id"] = "p";
    entries.append(ch);
    fs = build_drive_fs(entries);
    memo = memo_parent_names(fs);
    keys: list[str] = [];
    for k in memo {
        keys.append(k);
    }
    keys = sorted(keys);
    assert keys == ["p", "x"];;
    assert memo["x"] == "Par";;
    assert memo["p"] == "";;
}
