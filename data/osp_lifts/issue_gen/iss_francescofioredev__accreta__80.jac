"""francescofioredev/accreta#80 — OSP lineage without cyclic depth blow-up."""

node Entity {
    has node_id: str;
}

edge Parent {}

obj LineageStore {
    def init() {
        super.init();
    }

    def add_node(node_id: str, parent_id: str | None = None) -> None {
        visit [root -->][?:Entity, node_id == node_id] else {
            raise ValueError(f"duplicate node: {node_id}");
        }
        if parent_id is not None {
            parent = [root -->][?:Entity, node_id == parent_id];
            if not parent {
                raise KeyError(parent_id);
            }
            parent[0] +>:Parent:+> (n := Entity(node_id=node_id));
        } else {
            root ++> (n := Entity(node_id=node_id));
        }
    }

    def ancestors(node_id: str) -> list[str] {
        start = [root -->][?:Entity, node_id == node_id];
        if not start {
            raise KeyError(node_id);
        }
        w = root spawn AncestorWalker(target=node_id);
        return w.reports[0] if w.reports else [];
    }

    def descendants(node_id: str) -> list[str] {
        start = [root -->][?:Entity, node_id == node_id];
        if not start {
            raise KeyError(node_id);
        }
        w = root spawn DescendantWalker(target=node_id);
        ids = w.reports[0] if w.reports else [];
        return sorted(ids);
    }

    def depth_from(root_id: str, node_id: str) -> int | None {
        r = [root -->][?:Entity, node_id == root_id];
        if not r {
            raise KeyError(root_id);
        }
        w = root spawn DepthWalker(root_id=root_id, target=node_id);
        return w.reports[0] if w.reports else None;
    }

    def would_cycle(parent_id: str, child_id: str) -> bool {
        p = [root -->][?:Entity, node_id == parent_id];
        c = [root -->][?:Entity, node_id == child_id];
        if not p or not c {
            raise KeyError(parent_id if not p else child_id);
        }
        anc = self.ancestors(parent_id);
        return child_id in anc or parent_id == child_id;
    }
}

walker AncestorWalker {
    has target: str;
    has chain: list[str] = [];
    has claimed: dict = {};

    can start with Root entry {
        visit [root -->][?:Entity, node_id == self.target];
    }

    can step with Entity entry {
        visit [here <-:Parent:<-][?:Entity] else {
            disengage;
        }
    }

    can climb with Entity entry {
        parent = [here <-:Parent:<-][?:Entity];
        if not parent {
            disengage;
        }
        pid = parent[0].node_id;
        if pid in self.claimed {
            skip;
        }
        self.claimed[pid] = True;
        self.chain.append(pid);
        visit parent;
    }

    can finish with Root exit {
        report self.chain;
    }
}

walker DescendantWalker {
    has target: str;
    has out: list[str] = [];
    has claimed: dict = {};

    can start with Root entry {
        visit [root -->][?:Entity, node_id == self.target];
    }

    can walk with Entity entry {
        if here.node_id == self.target {
            visit [here ->:Parent:->][?:Entity];
            return;
        }
        nid = here.node_id;
        if nid in self.claimed {
            skip;
        }
        self.claimed[nid] = True;
        self.out.append(nid);
        visit [here ->:Parent:->][?:Entity];
    }

    can finish with Root exit {
        report self.out;
    }
}

walker DepthWalker {
    has root_id: str;
    has target: str;
    has depths: dict = {};
    has claimed: dict = {};
    has found: int | None = None;

    can start with Root entry {
        visit [root -->][?:Entity, node_id == self.root_id];
    }

    can walk with Entity entry {
        if here.node_id == self.root_id {
            self.depths[here.node_id] = 0;
            self.claimed[here.node_id] = True;
            visit [here ->:Parent:->][?:Entity];
            return;
        }
        if here.node_id in self.claimed {
            skip;
        }
        self.claimed[here.node_id] = True;
        # depth assigned on first visit only (cycle-safe)
        parent = [here <-:Parent:<-][?:Entity];
        if parent and parent[0].node_id in self.depths {
            self.depths[here.node_id] = self.depths[parent[0].node_id] + 1;
        }
        if here.node_id == self.target {
            self.found = self.depths.get(here.node_id);
        }
        visit [here ->:Parent:->][?:Entity];
    }

    can finish with Root exit {
        report self.found;
    }
}
