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
