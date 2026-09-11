"""genealogix/glx#198 — Genealogy relationship path and ancestor queries."""

node Person {
    has pid: str;
}

edge ParentOf {}

obj ArchiveStore {
    has people: dict[str, Person] = {};
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has limit: int = 0;
    has depth: int = 0;

    can step with Person entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        if self.depth > 0 and self.depth <= self.limit {
            self.found.append(here.pid);
        }
        self.depth += 1;
        if self.depth <= self.limit {
            visit [<-:ParentOf:<-][?:Person];
        }
    }
}

walker BfsPath {
    has target: str = "";
    has claimed: dict[str, bool] = {};
    has parent_of: dict[str, str] = {};
    has found: bool = False;

    can step with Person entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        if here.pid == self.target {
            self.found = True;
            disengage;
        }
        for nb in [here ->:ParentOf:->][?:Person] {
            if nb.pid not in self.parent_of {
                self.parent_of[nb.pid] = here.pid;
            }
        }
        for nb in [here <-:ParentOf:<-][?:Person] {
            if nb.pid not in self.parent_of {
                self.parent_of[nb.pid] = here.pid;
            }
        }
        visit [->:ParentOf:->][?:Person];
        visit [<-:ParentOf:<-][?:Person];
    }
}

def load_archive(
    person_ids: list[str],
    parent_edges: list[tuple[str, str]],
) -> ArchiveStore {
    arch = ArchiveStore();
    for pid in person_ids {
        nd = Person(pid=pid);
        root ++> nd;
        arch.people[pid] = nd;
    }
    for (parent, child) in parent_edges {
        p = arch.people.get(parent, None);
        c = arch.people.get(child, None);
        if p is not None and c is not None { p +>:ParentOf:+> c; }
    }
    return arch;
}

def _rebuild_path(parent_of: dict[str, str], start: str, end: str) -> list[str] {
    chain: list[str] = [end];
    cur = end;
    while cur != start {
        nxt = parent_of.get(cur, "");
        if nxt == "" { return []; }
        chain = [nxt] + chain;
        cur = nxt;
    }
    return chain;
}

def shortest_path(store: ArchiveStore, a: str, b: str) -> list[str] | None {
    if a not in store.people or b not in store.people { return None; }
    if a == b { return [a]; }
    start = store.people[a];
    w = start spawn BfsPath(target=b, claimed={}, parent_of={});
    if not w.found { return None; }
    return _rebuild_path(w.parent_of, a, b);
}

def ancestors(store: ArchiveStore, person: str, limit: int) -> list[str] {
    nd = store.people.get(person, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk(claimed={}, limit=limit);
    return sorted(w.found);
}

test "genealogy path and ancestors" {
    arch = load_archive(
        ["john", "mary", "ann", "bob"],
        [("john", "mary"), ("mary", "ann"), ("john", "bob")],
    );
    assert shortest_path(arch, "ann", "bob") == ["ann", "mary", "john", "bob"];
    assert ancestors(arch, "ann", 2) == ["john", "mary"];
    assert shortest_path(arch, "ann", "missing") is None;
}
