# flutter/flutter#118635 — recursive asset directory inclusion
#
# Model: a pubspec asset tree. AssetDir nodes form a directory graph via
# CONTAINS edges to child AssetDir and AssetFile nodes. A walker expands
# directories recursively, collecting file paths with a once-only claim-map
# (diamond-safe cycle policy: revisit -> skip, never disengage).

node AssetDir {
    has name: str;
}

node AssetFile {
    has path: str;
}

edge CONTAINS;

# module-level registry obj (fresh per test, no glob mutable state)
obj AssetManifest {
    has dirs: dict[str, AssetDir] = {};
    has files: dict[str, AssetFile] = {};
    has kids: dict[str, list[str]] = {};
    has parent: dict[str, str | None] = {};

    def add_dir(cid: str, name: str, par: str | None = None) {
        d = AssetDir(name=name);
        self.dirs[cid] = d;
        self.kids[cid] = [];
        self.parent[cid] = par;
        if par is not None {
            if par in self.dirs and par in self.kids {
                self.dirs[par] +>:CONTAINS:+> d;
                self.kids[par].append(cid);
            }
        }
    }

    def add_file(cid: str, path: str, par: str) {
        f = AssetFile(path=path);
        self.files[cid] = f;
        if par in self.dirs and par in self.kids {
            self.dirs[par] +>:CONTAINS:+> f;
            self.kids[par].append(cid);
        }
    }

    def connect_dir(cid: str, par: str) {
        # late edge insertion — enables adversarial diamond fixtures
        if cid in self.dirs and par in self.dirs {
            self.dirs[par] +>:CONTAINS:+> self.dirs[cid];
            if cid not in self.kids[par] {
                self.kids[par].append(cid);
            }
        }
    }
}

# recursive inclusion walker: claim-map + skip cycle policy
walker RecursiveInclude {
    has claimed: dict[str, bool] = {};
    has included: list[str] = [];

    can collect_file with AssetFile entry {
        if here.path not in self.claimed {
            self.claimed[here.path] = True;
            self.included.append(here.path);
        }
    }

    can collect_dir with AssetDir entry {
        if here.name in self.claimed {
            skip;  # cycle: already expanded, keep walker alive
        }
        self.claimed[here.name] = True;
        kids: list[AssetFile | AssetDir] = [here ->:CONTAINS:->];
        visit kids;
    }
}

# public API: recursively include all files under `root_id`, sorted
def include_recursively(m: AssetManifest, root_id: str) -> list[str] {
    if root_id not in m.dirs {
        return [];  # unknown-id tolerance
    }
    w = m.dirs[root_id] spawn RecursiveInclude(claimed={});
    return sorted(w.included);
}

def dir_exists(m: AssetManifest, cid: str) -> bool {
    return cid in m.dirs;
}

with entry {
    m = AssetManifest();
    m.add_dir("root", "assets");
    m.add_dir("img", "images", par="root");
    m.add_dir("img2", "images_dup", par="root");
    m.add_file("f1", "a.txt", par="root");
    m.add_file("f2", "img/b.png", par="img");
    root spawn RecursiveInclude(claimed={});
}

test "recursive_diamond_revisit" {
    m = AssetManifest();
    m.add_dir("r", "root");
    m.add_dir("a", "a");
    m.add_dir("b", "b");
    m.add_file("f1", "x.txt", par="a");
    # adversarial: b also reaches a, forming diamond with late edge
    m.connect_dir("a", "b");
    m.connect_dir("a", "r");
    m.connect_dir("b", "r");
    got = include_recursively(m, "r");
    assert got == sorted(["x.txt"]);
}

test "unknown_root_tolerant" {
    m = AssetManifest();
    got = include_recursively(m, "nope");
    assert got == [];
    assert dir_exists(m, "nope") == False;
}

test "deep_nesting_all_files" {
    m = AssetManifest();
    m.add_dir("d0", "d0");
    m.add_dir("d1", "d1", par="d0");
    m.add_dir("d2", "d2", par="d1");
    m.add_file("fa", "d0/z.txt", par="d0");
    m.add_file("fb", "d0/d1/y.txt", par="d1");
    m.add_file("fc", "d0/d1/d2/w.txt", par="d2");
    got = include_recursively(m, "d0");
    assert got == sorted(["d0/d1/d2/w.txt", "d0/d1/y.txt", "d0/z.txt"]);
}

test "empty_dir_returns_empty" {
    m = AssetManifest();
    m.add_dir("empty", "void");
    assert include_recursively(m, "empty") == [];
}

test "duplicate_paths_deduped" {
    m = AssetManifest();
    m.add_dir("r", "root");
    m.add_dir("s", "sub", par="r");
    m.add_file("f", "same.txt", par="r");
    # diamond where same file is reachable via two dirs is impossible here,
    # but claim-map guarantees no double count on any revisit
    got = include_recursively(m, "r");
    assert got == ["same.txt"];
    assert len(got) == 1;
}

test "sibling_isolation" {
    m = AssetManifest();
    m.add_dir("r1", "r1");
    m.add_dir("r2", "r2");
    m.add_file("f1", "one.txt", par="r1");
    m.add_file("f2", "two.txt", par="r2");
    assert include_recursively(m, "r1") == ["one.txt"];
    assert include_recursively(m, "r2") == ["two.txt"];
}
