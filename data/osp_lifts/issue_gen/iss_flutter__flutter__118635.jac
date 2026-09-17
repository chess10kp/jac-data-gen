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
