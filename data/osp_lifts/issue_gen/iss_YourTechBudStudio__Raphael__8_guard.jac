node Node {
    has id: str;
    has slug: str;
    has revision: int = 1;
    has parent_id: str | None = None;
}

edge Child {}

edge ArchivedBy {
    has owner: str = "user";
    has reason_key: str = "direct_user";
    has active: bool = True;
}

obj Store {
    has nodes: dict[str, Node] = {};
    has kids: dict[str, list[str]] = {};
    has parent: dict[str, str] = {};

    def add_node(nid: str, slug: str, parent_id: str | None) -> Node {
        n = Node(id=nid, slug=slug, parent_id=parent_id);
        self.nodes[nid] = n;
        self.kids[nid] = [];
        if parent_id is not None {
            self.parent[nid] = parent_id;
            p: Node = self.nodes[parent_id];
            p +>:Child:+> n;
            self.kids[parent_id].append(nid);
        }
        return n;
    }

    def direct_cause(nid: str) -> list[ArchivedBy] {
        n: Node = self.nodes[nid];
        return [n ->:ArchivedBy:->ArchivedBy];
    }

    def active_causes(nid: str) -> list[ArchivedBy] {
        out: list[ArchivedBy] = [];
        for c in self.direct_cause(nid) {
            if c.active {
                out.append(c);
            }
        }
        return out;
    }

    def origins(nid: str) -> list[str] {
        found: list[str] = [];
        cur: str | None = nid;
        while cur is not None {
            if cur in self.nodes {
                if len(self.active_causes(cur)) > 0 {
                    found.append(cur);
                }
            }
            cur = self.parent.get(cur);
        }
        return found;
    }

    def is_archived(nid: str) -> bool {
        return len(self.origins(nid)) > 0;
    }

    def archive(nid: str, owner: str = "user") -> dict {
        if self.is_archived(nid) {
            for c in self.active_causes(nid) {
                if c.owner == owner {
                    return {"nid": nid, "archived": True, "dup": True};
                }
            }
        }
        n: Node = self.nodes[nid];
        e = ArchivedBy(owner=owner);
        n +>:ArchivedBy:+> e;
        n.revision = n.revision + 1;
        return {"nid": nid, "archived": True, "rev": n.revision};
    }

    def restore(nid: str) -> dict {
        n: Node = self.nodes[nid];
        # retire all direct user causes: flip active flag (two-phase mutation,
        # no in-walk edge deletion needed)
        for c in self.direct_cause(nid) {
            if c.owner == "user" and c.active {
                c.active = False;
            }
        }
        n.revision = n.revision + 1;
        return {"nid": nid, "archived": self.is_archived(nid), "rev": n.revision};
    }

    def active_children(nid: str) -> list[str] {
        out: list[str] = [];
        for k in sorted(self.kids[nid]) {
            if not self.is_archived(k) {
                out.append(k);
            }
        }
        return out;
    }
}

walker Sweep {
    has seen: dict[str, bool] = {};
    has collected: list[str] = [];

    can step with Store entry {
        here = here;
        s: Store = here;
        for nid in sorted(s.nodes.keys()) {
            if nid in self.seen {
                continue;
            }
            self.seen[nid] = True;
            if s.is_archived(nid) {
                self.collected.append(nid);
            }
        }
        print("archived:", sorted(self.collected));
        disengage;
    }
}

test "archive_dup_and_rev" {
    s = Store();
    s.add_node("a", "root", None);
    r1 = s.archive("a");
    assert r1["archived"] == True;
    assert r1["rev"] == 2;
    r2 = s.archive("a");
    assert r2.get("dup") == True;
    assert s.is_archived("a") == True;
}

test "restore_clears_user_only" {
    s = Store();
    s.add_node("a", "root", None);
    s.archive("a", "user");
    s.archive("a", "system");
    r = s.restore("a");
    assert r["archived"] == True;
    assert s.is_archived("a") == True;
    s.restore("a");
    assert s.is_archived("a") == False;
}

test "origins_chain_inheritance" {
    s = Store();
    s.add_node("p", "parent", None);
    s.add_node("c", "child", "p");
    s.add_node("g", "grand", "c");
    assert s.is_archived("g") == False;
    s.archive("p");
    assert s.is_archived("c") == True;
    assert s.is_archived("g") == True;
    assert s.origins("g") == ["p"];
    s.restore("p");
    assert s.is_archived("g") == False;
}

test "active_children_sorted" {
    s = Store();
    s.add_node("r", "root", None);
    s.add_node("z", "z", "r");
    s.add_node("a", "a", "r");
    s.add_node("q", "q", "r");
    s.archive("q");
    assert s.active_children("r") == ["a", "z"];
    s.archive("z", "system");
    s.restore("z");
    assert s.active_children("r") == ["a", "z"];
}
