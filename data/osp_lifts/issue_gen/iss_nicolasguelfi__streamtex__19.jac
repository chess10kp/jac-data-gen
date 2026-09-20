"""ProjectBlockRegistry shared block directories - nicolasguelfi/streamtex#19."""

node ScanDir {
    has cid: str;
    has path: str;
    has source: str;
    has priority: int;
}

node BlockEntry {
    has name: str;
    has rel_path: str;
    has block_type: str;
    has source: str;
    has source_dir: str;
    has subdirectory: str | None = None;
    has loaded: bool = False;
}

edge DirTree {}
edge HousesBlock {}

walker DirScanWalker {
    has claimed: dict[str, bool] = {};
    has handle: dict;
    has local_seen: dict[str, str] = {};
    has local_collisions: list[list[str]] = [];

    can step with ScanDir entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ("scan", here.path);
        manifest = self.handle["manifest"] as dict;
        files: list[BlockEntry] = [here ->:HousesBlock:->][?:BlockEntry];
        for bf in files {
            be: BlockEntry = bf;
            nm = be.name;
            if nm in manifest {
                continue;
            }
            if nm in self.local_seen {
                oldp = self.local_seen[nm];
                row: list[str] = [nm, oldp, be.rel_path];
                self.local_collisions.append(row);
                continue;
            }
            self.local_seen[nm] = be.rel_path;
            rec: dict = {};
            rec["path"] = be.rel_path;
            rec["loaded"] = be.loaded;
            rec["type"] = be.block_type;
            rec["source"] = be.source;
            rec["source_dir"] = be.source_dir;
            rec["subdirectory"] = be.subdirectory;
            manifest[nm] = rec;
        }
        kids: list[ScanDir] = [here ->:DirTree:->][?:ScanDir];
        ordered: list[ScanDir] = [];
        for k in kids {
            ordered.append(k);
        }
        i = 0;
        while i < len(ordered) {
            j = i + 1;
            while j < len(ordered) {
                a = ordered[i] as ScanDir;
                b = ordered[j] as ScanDir;
                if b.path < a.path {
                    ordered[i] = b;
                    ordered[j] = a;
                }
                j += 1;
            }
            i += 1;
        }
        if ordered {
            visit ordered;
        } else {
            disengage;
        }
    }
}

def block_stem(filename: str) -> str {
    if filename.endswith(".py") {
        return filename[0 : len(filename) - 3];
    }
    return filename;
}

def make_registry(blocks_dir: str, shared: list[str] | None = None, auto_shared: bool = True) -> dict {
    sh: list[str] = [];
    if shared {
        for p in shared {
            sh.append(p);
        }
    }
    dirs: dict[str, ScanDir] = {};
    blocks: dict[str, BlockEntry] = {};
    manifest: dict = {};
    cols: list[list[str]] = [];
    sr: list[ScanDir] = [];
    handle: dict = {};
    handle["blocks_dir"] = blocks_dir;
    handle["shared"] = sh;
    handle["auto_shared"] = auto_shared;
    handle["dirs"] = dirs;
    handle["blocks"] = blocks;
    handle["manifest"] = manifest;
    handle["collisions"] = cols;
    handle["scan_roots"] = sr;
    return handle;
}

def wire_scan_dir(handle: dict, path: str, source: str, priority: int, parent_path: str | None = None) {
    dirs = handle["dirs"] as dict[str, ScanDir];
    nd = ScanDir(cid=path, path=path, source=source, priority=priority);
    dirs[path] = nd;
    root ++> nd;
    if parent_path {
        par = dirs[parent_path] as ScanDir;
        par +>:DirTree:+> nd;
    } else {
        sr = handle["scan_roots"] as list[ScanDir];
        sr.append(nd);
    }
}

def wire_block(handle: dict, dir_path: str, filename: str, block_type: str = "composite") {
    full_rel = dir_path + "/" + filename;
    if "_atomic/" in full_rel {
        return;
    }
    dirs = handle["dirs"] as dict[str, ScanDir];
    blocks = handle["blocks"] as dict[str, BlockEntry];
    d = dirs[dir_path] as ScanDir;
    stem = block_stem(filename);
    sub: str | None = None;
    prefix = d.path + "/";
    if dir_path.startswith(prefix) {
        tail = dir_path[len(prefix) : len(dir_path)];
        if tail {
            sub = tail;
        }
    }
    be = BlockEntry(
        name=stem,
        rel_path=full_rel,
        block_type=block_type,
        source=d.source,
        source_dir=d.path,
        subdirectory=sub,
    );
    blocks[full_rel] = be;
    d +>:HousesBlock:+> be;
}

def scan_registry(handle: dict) -> dict {
    roots = handle["scan_roots"] as list[ScanDir];
    ordered: list[ScanDir] = [];
    for r in roots {
        ordered.append(r);
    }
    i = 0;
    while i < len(ordered) {
        j = i + 1;
        while j < len(ordered) {
            a = ordered[i] as ScanDir;
            b = ordered[j] as ScanDir;
            if b.priority < a.priority {
                ordered[i] = b;
                ordered[j] = a;
            }
            j += 1;
        }
        i += 1;
    }
    cols = handle["collisions"] as list[list[str]];
    for r in ordered {
        w = r spawn DirScanWalker(handle=handle);
        lc = w.local_collisions;
        for row in lc {
            cols.append(row);
        }
    }
    return handle["manifest"] as dict;
}

def list_block_names(handle: dict) -> list[str] {
    manifest = handle["manifest"] as dict;
    names: list[str] = [];
    for k in manifest {
        names.append(k);
    }
    return sorted(names);
}

def lookup_block(handle: dict, name: str) -> dict | None {
    manifest = handle["manifest"] as dict;
    if name in manifest {
        return manifest[name] as dict;
    }
    return None;
}

def get_collisions(handle: dict) -> list[list[str]] {
    cols = handle["collisions"] as list[list[str]];
    out: list[list[str]] = [];
    for row in cols {
        out.append(row);
    }
    return out;
}
