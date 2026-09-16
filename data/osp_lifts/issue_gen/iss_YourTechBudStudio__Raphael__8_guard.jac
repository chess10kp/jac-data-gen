# YourTechBudStudio/Raphael#8 — archive/restore with cause inheritance
node Note {
    has id: str;
    has slug: str;
    has parent_id: str | None = None;
    has revision: int = 1;
    has content: str = "";
}

edge Child {}

# cause stored only at origin; effective = self or any ancestor cause
node Cause {
    has node_id: str;
    has owner: str;
    has reason_key: str;
}

obj ArchiveStore {
    has nodes: dict[str, Note] = {};
    has causes: dict[str, list[Cause]] = {};
    has order: list[str] = [];

    def add(id: str, slug: str, parent_id: str | None, content: str) -> Note {
        nd = Note(id=id, slug=slug, parent_id=parent_id, content=content);
        self.nodes[id] = nd;
        self.causes[id] = [];
        self.order.append(id);
        if parent_id is not None and parent_id in self.nodes {
            self.nodes[parent_id] +>:Child:+> nd;
        }
        return nd;
    }

    def ancestors_of(id: str) -> list[str] {
        chain: list[str] = [];
        cur: str | None = id;
        while cur is not None and cur in self.nodes {
            chain.append(cur);
            cur = self.nodes[cur].parent_id;
        }
        return chain;
    }

    # causes at origins are inherited through ancestry
    def effective_causes(id: str) -> list[Cause] {
        found: list[Cause] = [];
        for aid in self.ancestors_of(id) {
            for c in self.causes[aid] { found.append(c); }
        }
        return found;
    }

    def is_archived(id: str) -> bool {
        return len(self.effective_causes(id)) > 0;
    }

    def origin_ids(id: str) -> list[str] {
        out: list[str] = [];
        for aid in self.ancestors_of(id) {
            if len(self.causes[aid]) > 0 { out.append(aid); }
        }
        return out;
    }

    # ordinary user restore removes only direct user cause at target
    def archive(id: str, revision: int) -> dict {
        if id not in self.nodes { return {"ok": False, "error": "unknown_id"}; }
        if self.is_archived(id) { return {"ok": False, "error": "already_archived"}; }
        self.causes[id].append(Cause(node_id=id, owner="user", reason_key="direct"));
        self.nodes[id].revision = revision + 1;
        return {"ok": True, "id": id, "revision": self.nodes[id].revision,
                "archived": True};
    }

    def restore(id: str, revision: int) -> dict {
        if id not in self.nodes { return {"ok": False, "error": "unknown_id"}; }
        kept: list[Cause] = [];
        for c in self.causes[id] {
            if not (c.owner == "user" and c.reason_key == "direct") {
                kept.append(c);
            }
        }
        self.causes[id] = kept;
        self.nodes[id].revision = revision + 1;
        return {"ok": True, "id": id, "revision": self.nodes[id].revision,
                "archived": self.is_archived(id)};
    }

    # archived destinations reject moves; inherited-only archived may relocate
    def move(id: str, new_parent: str) -> dict {
        if id not in self.nodes or new_parent not in self.nodes {
            return {"ok": False, "error": "unknown_id"};
        }
        direct_archived: bool = len(self.causes[id]) > 0;
        if direct_archived { return {"ok": False, "error": "directly_archived"}; }
        if self.is_archived(new_parent) { return {"ok": False, "error": "archived_destination"}; }
        nd = self.nodes[id];
        nd.parent_id = new_parent;
        self.nodes[new_parent] +>:Child:+> nd;
        return {"ok": True, "id": id};
    }

    # list excludes effectively archived by default
    def list_nodes(include_archived: bool = False) -> list[str] {
        ids: list[str] = [];
        for nid in self.order {
            if include_archived or not self.is_archived(nid) { ids.append(nid); }
        }
        return ids;
    }
}

walker StatusProbe {
    has target: str = "";
    can step with ArchiveStore entry {
        blocked: bool = here.is_archived(self.target);
        origins: list[str] = here.origin_ids(self.target);
        print(self.target, blocked, sorted(origins));
    }
}

def get_status(store: ArchiveStore, id: str) -> dict {
    return {"id": id, "archived": store.is_archived(id),
            "origins": store.origin_ids(id)};
}

test "add_and_list" {
    st = ArchiveStore();
    st.add("a", "A", None, "root");
    st.add("b", "B", "a", "child");
    assert sorted(st.list_nodes(True)) == ["a", "b"];
    assert st.ancestors_of("b") == ["b", "a"];
}

test "archive_inherits_and_restore" {
    st = ArchiveStore();
    st.add("a", "A", None, "root");
    st.add("b", "B", "a", "child");
    r = st.archive("a", 1);
    assert r["ok"] == True;
    assert st.is_archived("b") == True;
    assert get_status(st, "b")["origins"] == ["a"];
    r2 = st.restore("b", 2);
    assert r2["archived"] == True;
    r3 = st.restore("a", 3);
    assert r3["archived"] == False;
    assert st.list_nodes() == ["a", "b"];
}

test "move_guards" {
    st = ArchiveStore();
    st.add("a", "A", None, "r");
    st.add("b", "B", None, "b");
    st.add("c", "C", "b", "c");
    st.archive("b", 1);
    m = st.move("c", "a");
    assert m == {"ok": True, "id": "c"};
    m2 = st.move("c", "b");
    assert m2 == {"ok": False, "error": "archived_destination"};
    m3 = st.move("b", "a");
    assert m3 == {"ok": False, "error": "directly_archived"};
    m4 = st.move("zz", "a");
    assert m4 == {"ok": False, "error": "unknown_id"};
}

test "status_probe_walker" {
    st = ArchiveStore();
    st.add("a", "A", None, "r");
    st.add("b", "B", "a", "c");
    st.archive("a", 1);
    w = st spawn StatusProbe(target="b");
    assert w.target == "b";
}
