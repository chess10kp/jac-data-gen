"""tjmisko/Coldstore#7 — tag catalog subtree list, merge, cascade delete (OSP lift)."""

obj TagCatalog { has stamp: int = 0; }

node Tag { has path: str; }

edge SubtagOf {}

walker Descendants {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for t in [-->][?:Tag] {
            if t.path == self.start { visit [t]; }
        }
    }

    can step with Tag entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.path != self.start { self.found.append(here.path); }
        visit [->:SubtagOf:->][?:Tag];
    }

    can finish with Root exit { report self.found; }
}

walker CollectDelete {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for t in [-->][?:Tag] {
            if t.path == self.start { visit [t]; }
        }
    }

    can step with Tag entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        self.found.append(here.path);
        visit [->:SubtagOf:->][?:Tag];
    }

    can finish with Root exit { report self.found; }
}

def _tag(path: str) -> Tag | None {
    for t in [-->][?:Tag] { if t.path == path { return t; } }
    return None;
}

def _path_depth(p: str) -> int { return p.count("/"); }

def _wire(paths: list[str]) {
    mp: dict[str, Tag] = {};
    for raw in paths {
        parts = [p for p in raw.split("/") if p];
        for i in range(len(parts)) {
            name = "/".join(parts[: i + 1]);
            if name in mp { continue; }
            n = Tag(path=name);
            root ++> n;
            mp[name] = n;
            if i > 0 {
                par_name = "/".join(parts[:i]);
                if par_name in mp {
                    parent = mp[par_name];
                    parent +>:SubtagOf:+> n;
                }
            }
        }
    }
}

def _remove_tag_node(t: Tag) {
    for ch in [t ->:SubtagOf:->][?:Tag] { t del ->:SubtagOf:-> ch; }
    for par in [t <-:SubtagOf:<-][?:Tag] { par del ->:SubtagOf:-> t; }
    del t;
}

def load_tags(paths: list[str]) -> TagCatalog {
    _wire(paths);
    return TagCatalog(stamp=1);
}

def descendant_tags(c: TagCatalog, name: str) -> list[str] {
    _ = c;
    if _tag(name) is None { return []; }
    w = root spawn Descendants(start=name, claimed={}, found=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def delete_tag(c: TagCatalog, name: str, cascade: bool = False) -> list[str] {
    _ = c;
    if _tag(name) is None { return []; }
    kids = descendant_tags(c, name);
    if kids and not cascade { raise ValueError("has_descendants"); }
    w = root spawn CollectDelete(start=name, claimed={}, found=[]);
    doomed = sorted(w.reports[0] if w.reports else []);
    by_depth = sorted(doomed, key=_path_depth, reverse=True);
    for p in by_depth {
        t = _tag(p);
        if t is not None { _remove_tag_node(t); }
    }
    return doomed;
}

def merge_tags(c: TagCatalog, src: str, dst: str) -> bool {
    _ = c;
    s = _tag(src);
    d = _tag(dst);
    if s is None or d is None { return False; }
    kids: list[Tag] = [];
    for ch in [s ->:SubtagOf:->][?:Tag] { kids.append(ch); }
    for ch in kids {
        s del ->:SubtagOf:-> ch;
        d +>:SubtagOf:+> ch;
    }
    _remove_tag_node(s);
    return True;
}
