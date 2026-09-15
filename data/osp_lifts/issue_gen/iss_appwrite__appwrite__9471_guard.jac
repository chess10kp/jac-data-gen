"""Self-referencing collection hierarchy — appwrite/appwrite#9471."""

node Document {
    has cid: str;
    has label: str;
}

edge ParentChild {}

obj SelfCollection {
    has store_root: Document;

    def init {
        self.store_root = Document(cid="", label="__root__");
    }

    def _find(self, doc_id: str) -> Document | None {
        w = self.store_root spawn FindDocWalker(target=doc_id);
        return w.found;
    }

    def add(self, doc_id: str, parent_id: str | None = None) -> bool {
        if doc_id == "" {
            return False;
        }
        if self._find(doc_id) {
            return False;
        }
        if parent_id == doc_id {
            return False;
        }
        nd = Document(cid=doc_id, label=doc_id);
        if parent_id {
            parent = self._find(parent_id);
            if not parent {
                return False;
            }
            if self.would_create_cycle(doc_id, parent_id) {
                return False;
            }
            parent +>:ParentChild:+> nd;
        } else {
            self.store_root ++> nd;
        }
        return True;
    }

    def connect(self, parent_id: str, child_id: str) -> bool {
        if parent_id == child_id {
            return False;
        }
        parent = self._find(parent_id);
        child = self._find(child_id);
        if not parent {
            return False;
        }
        if not child {
            return False;
        }
        if self.would_create_cycle(child_id, parent_id) {
            return False;
        }
        parent +>:ParentChild:+> child;
        return True;
    }

    def would_create_cycle(self, child_id: str, parent_id: str) -> bool {
        if child_id == parent_id {
            return True;
        }
        child = self._find(child_id);
        if not child {
            return False;
        }
        parent = self._find(parent_id);
        if not parent {
            return False;
        }
        w = parent spawn AncestorReachWalker(target=child_id, claimed={});
        return w.reached;
    }

    def ancestors(self, doc_id: str) -> list[str] {
        nd = self._find(doc_id);
        if not nd {
            anc: list[str] = [];
            return anc;
        }
        w = nd spawn AncestorsWalker(claimed={});
        return w.result;
    }

    def descendants(self, doc_id: str) -> list[str] {
        nd = self._find(doc_id);
        if not nd {
            des: list[str] = [];
            return des;
        }
        w = nd spawn DescendantsWalker(claimed={});
        return w.result;
    }

    def depth(self, doc_id: str) -> int {
        nd = self._find(doc_id);
        if not nd {
            return -1;
        }
        w = nd spawn AncestorsWalker(claimed={});
        return len(w.result);
    }
}

def make_collection -> SelfCollection {
    c = SelfCollection();
    return c;
}

walker FindDocWalker {
    has target: str;
    has found: Document | None = None;

    can search with Document entry {
        if here.cid == self.target {
            self.found = here;
            disengage;
        }
        for ch in [here ->:ParentChild:->][?:Document] {
            visit ch;
        }
        print ["find", here.cid, self.found];
    }
}

walker AncestorReachWalker {
    has target: str;
    has reached: bool = False;
    has claimed: dict[str, bool] = {};

    can climb with Document entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.reached = True;
            disengage;
        }
        for p in [here <-:ParentChild:<-][?:Document] {
            visit p;
        }
        print ["reach", here.cid, self.reached];
    }
}

walker AncestorsWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];

    can climb with Document entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        for p in [here <-:ParentChild:<-][?:Document] {
            if p.cid != "" {
                self.result.append(p.cid);
            }
            visit p;
        }
        print ["ancestors", here.cid, self.result];
    }
}

walker DescendantsWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];

    can descend with Document entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        kids: list[Document] = [here ->:ParentChild:->][?:Document];
        for ch in kids {
            if ch.cid != "" {
                self.result.append(ch.cid);
            }
            visit :0: ch;
        }
        print ["descendants", here.cid, self.result];
    }
}

"""Self-referencing collection hierarchy — appwrite/appwrite#9471."""

node Document {
    has cid: str;
    has label: str;
}

edge ParentChild {}

obj SelfCollection {
    has store_root: Document;

    def init {
        self.store_root = Document(cid="", label="__root__");
    }

    def _find(self, doc_id: str) -> Document | None {
        w = self.store_root spawn FindDocWalker(target=doc_id);
        return w.found;
    }

    def add(self, doc_id: str, parent_id: str | None = None) -> bool {
        if doc_id == "" {
            return False;
        }
        if self._find(doc_id) {
            return False;
        }
        if parent_id == doc_id {
            return False;
        }
        nd = Document(cid=doc_id, label=doc_id);
        if parent_id {
            parent = self._find(parent_id);
            if not parent {
                return False;
            }
            if self.would_create_cycle(doc_id, parent_id) {
                return False;
            }
            parent +>:ParentChild:+> nd;
        } else {
            self.store_root ++> nd;
        }
        return True;
    }

    def connect(self, parent_id: str, child_id: str) -> bool {
        if parent_id == child_id {
            return False;
        }
        parent = self._find(parent_id);
        child = self._find(child_id);
        if not parent {
            return False;
        }
        if not child {
            return False;
        }
        if self.would_create_cycle(child_id, parent_id) {
            return False;
        }
        parent +>:ParentChild:+> child;
        return True;
    }

    def would_create_cycle(self, child_id: str, parent_id: str) -> bool {
        if child_id == parent_id {
            return True;
        }
        child = self._find(child_id);
        if not child {
            return False;
        }
        parent = self._find(parent_id);
        if not parent {
            return False;
        }
        w = parent spawn AncestorReachWalker(target=child_id, claimed={});
        return w.reached;
    }

    def ancestors(self, doc_id: str) -> list[str] {
        nd = self._find(doc_id);
        if not nd {
            anc: list[str] = [];
            return anc;
        }
        w = nd spawn AncestorsWalker(claimed={});
        return w.result;
    }

    def descendants(self, doc_id: str) -> list[str] {
        nd = self._find(doc_id);
        if not nd {
            des: list[str] = [];
            return des;
        }
        w = nd spawn DescendantsWalker(claimed={});
        return w.result;
    }

    def depth(self, doc_id: str) -> int {
        nd = self._find(doc_id);
        if not nd {
            return -1;
        }
        w = nd spawn AncestorsWalker(claimed={});
        return len(w.result);
    }
}

def make_collection -> SelfCollection {
    c = SelfCollection();
    return c;
}

walker FindDocWalker {
    has target: str;
    has found: Document | None = None;

    can search with Document entry {
        if here.cid == self.target {
            self.found = here;
            disengage;
        }
        for ch in [here ->:ParentChild:->][?:Document] {
            visit ch;
        }
        print ["find", here.cid, self.found];
    }
}

walker AncestorReachWalker {
    has target: str;
    has reached: bool = False;
    has claimed: dict[str, bool] = {};

    can climb with Document entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.reached = True;
            disengage;
        }
        for p in [here <-:ParentChild:<-][?:Document] {
            visit p;
        }
        print ["reach", here.cid, self.reached];
    }
}

walker AncestorsWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];

    can climb with Document entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        for p in [here <-:ParentChild:<-][?:Document] {
            if p.cid != "" {
                self.result.append(p.cid);
            }
            visit p;
        }
        print ["ancestors", here.cid, self.result];
    }
}

walker DescendantsWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];

    can descend with Document entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        kids: list[Document] = [here ->:ParentChild:->][?:Document];
        for ch in kids {
            if ch.cid != "" {
                self.result.append(ch.cid);
            }
            visit :0: ch;
        }
        print ["descendants", here.cid, self.result];
    }
}

test "add_and_ancestors" {
    c = make_collection();
    assert c.add("a");
    assert c.add("b", "a");
    assert c.add("c", "b");
    assert c.ancestors("c") == ["b", "a"];
}

test "reject_self_parent" {
    c = make_collection();
    assert c.add("x");
    assert not c.add("x", "x");
    assert not c.connect("x", "x");
}

test "cycle_blocked_on_add" {
    c = make_collection();
    assert c.add("p");
    assert c.add("q", "p");
    assert c.add("r", "q");
    assert not c.add("p", "r");
    assert c.would_create_cycle("p", "r");
}

test "descendants_dfs" {
    c = make_collection();
    assert c.add("root");
    assert c.add("l", "root");
    assert c.add("r", "root");
    assert c.add("ll", "l");
    assert c.descendants("root") == ["l", "ll", "r"];
}

test "depth_and_missing" {
    c = make_collection();
    assert c.add("a");
    assert c.add("b", "a");
    assert c.depth("b") == 1;
    assert c.depth("missing") == -1;
    assert c.ancestors("missing") == [];
}

test "connect_valid" {
    c = make_collection();
    assert c.add("m");
    assert c.add("n");
    assert c.connect("m", "n");
    assert c.ancestors("n") == ["m"];
}
