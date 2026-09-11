"""Growth-Circle/cadis#259 — directory index walk with symlink cycle guard."""

glob MAX_WALK: int = 128;

node DirNode {
    has path: str;
}

edge ChildOf {}

edge SymlinkTo {}

obj DirIndex {
    has dirs: dict[str, DirNode] = {};
}

walker IndexWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has steps: int = 0;
    has cycle_hit: bool = False;

    can step with DirNode entry {
        if self.steps >= MAX_WALK { disengage; }
        self.steps += 1;
        if here.path in self.claimed {
            self.cycle_hit = True;
            skip;
        }
        self.claimed[here.path] = True;
        self.order.append(here.path);
        visit [->:ChildOf:->][?:DirNode];
        for tgt in [here ->:SymlinkTo:->][?:DirNode] {
            if tgt.path in self.claimed { self.cycle_hit = True; skip; }
            visit [tgt];
        }
    }
}

def load_dir_index(
    dirs: list[str],
    child_edges: list[tuple[str, str]],
    symlinks: list[tuple[str, str]] | None = None,
) -> DirIndex {
    idx = DirIndex();
    for d in dirs {
        nd = DirNode(path=d);
        root ++> nd;
        idx.dirs[d] = nd;
    }
    for (parent, child) in child_edges {
        p = idx.dirs.get(parent, None);
        c = idx.dirs.get(child, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    if symlinks is not None {
        for (link, target) in symlinks {
            ln = idx.dirs.get(link, None);
            tg = idx.dirs.get(target, None);
            if ln is not None and tg is not None { ln +>:SymlinkTo:+> tg; }
        }
    }
    return idx;
}

def indexed_paths(idx: DirIndex, `root: str) -> list[str] {
    nd = idx.dirs.get(`root, None);
    if nd is None { return []; }
    w = nd spawn IndexWalk();
    return sorted(w.order);
}

def walk_terminates(idx: DirIndex, `root: str) -> bool {
    nd = idx.dirs.get(`root, None);
    if nd is None { return True; }
    w = nd spawn IndexWalk();
    return w.steps < MAX_WALK;
}

def cycle_detected(idx: DirIndex, `root: str) -> bool {
    nd = idx.dirs.get(`root, None);
    if nd is None { return False; }
    w = nd spawn IndexWalk();
    return w.cycle_hit;
}
