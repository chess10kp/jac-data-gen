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
