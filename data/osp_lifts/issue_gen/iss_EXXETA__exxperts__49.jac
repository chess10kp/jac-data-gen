"""EXXETA/exxperts#49 — recursive skill directory scan with symlink cycle guard."""

glob MAX_SCAN: int = 256;

node SkillDir {
    has path: str;
    has has_skill: bool = False;
}

edge ChildDir {}

edge SymlinkTo {}

obj SkillIndex {
    has dirs: dict[str, SkillDir] = {};
}

walker SkillScan {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has steps: int = 0;
    has cycle_hit: bool = False;

    can step with SkillDir entry {
        if self.steps >= MAX_SCAN { disengage; }
        self.steps += 1;
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.has_skill { self.found.append(here.path); }
        visit [->:ChildDir:->][?:SkillDir];
        for tgt in [here ->:SymlinkTo:->][?:SkillDir] {
            if tgt.path in self.claimed { self.cycle_hit = True; skip; }
            visit [tgt];
        }
    }
}

def load_skill_index(
    dirs: list[str],
    child_edges: list[tuple[str, str]],
    symlinks: list[tuple[str, str]] | None = None,
    skill_dirs: list[str] | None = None,
) -> SkillIndex {
    idx = SkillIndex();
    skill_set: dict[str, bool] = {};
    if skill_dirs is not None {
        for d in skill_dirs { skill_set[d] = True; }
    }
    for d in dirs {
        nd = SkillDir(path=d, has_skill=d in skill_set);
        root ++> nd;
        idx.dirs[d] = nd;
    }
    for (parent, child) in child_edges {
        p = idx.dirs.get(parent, None);
        c = idx.dirs.get(child, None);
        if p is not None and c is not None { p +>:ChildDir:+> c; }
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

def discover_skills(idx: SkillIndex, `root: str) -> list[str] {
    nd = idx.dirs.get(`root, None);
    if nd is None { return []; }
    w = nd spawn SkillScan();
    return sorted(w.found);
}

def scan_visit_count(idx: SkillIndex, `root: str) -> int {
    nd = idx.dirs.get(`root, None);
    if nd is None { return 0; }
    w = nd spawn SkillScan();
    return len(w.claimed.keys());
}

def has_symlink_cycle(idx: SkillIndex, `root: str) -> bool {
    nd = idx.dirs.get(`root, None);
    if nd is None { return False; }
    w = nd spawn SkillScan();
    return w.cycle_hit;
}
