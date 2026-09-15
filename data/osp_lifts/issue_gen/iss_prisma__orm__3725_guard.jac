"""Recursive category relationships — prisma/orm#3725."""

node Category {
    has cid: str;
    has name: str;
}

edge ParentOf {}

walker DescendantsWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can descend with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        kids: list[Category] = [here ->:ParentOf:->][?:Category];
        visit :0: kids else { disengage; }
    }

    can seed with ? entry {
        tops: list[Category] = [root -->][?:Category];
        print("descendants-demo");
        visit :0: tops else { disengage; }
    }
}

walker AncestorsWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has start_id: str;

    can climb with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        if here.cid != self.start_id {
            self.found.append(here.cid);
        }
        parents: list[Category] = [here <-:ParentOf:<-][?:Category];
        visit :0: parents else { disengage; }
    }
}

obj CategoryStore {
    has nodes: dict[str, Category] = {};

    def add_category(cid: str, name: str, parent_id: str | None = None) -> bool {
        if cid in self.nodes { return False; }
        if parent_id is not None and parent_id not in self.nodes { return False; }
        nd = Category(cid=cid, name=name);
        self.nodes[cid] = nd;
        if parent_id is not None {
            par = self.nodes[parent_id];
            par +>:ParentOf:+> nd;
        } else {
            root ++> nd;
        }
        return True;
    }

    def get_descendants(root_id: str) -> list[str] {
        if root_id not in self.nodes { return []; }
        start_nd = self.nodes[root_id];
        w = start_nd spawn DescendantsWalker(claimed={});
        out: list[str] = [];
        for x in w.found { out.append(x); }
        return out;
    }

    def get_ancestors(cat_id: str) -> list[str] {
        if cat_id not in self.nodes { return []; }
        start_nd = self.nodes[cat_id];
        w = start_nd spawn AncestorsWalker(claimed={}, start_id=cat_id);
        out: list[str] = [];
        for x in w.found { out.append(x); }
        return out;
    }

    def remove_category(cid: str) -> bool {
        if cid not in self.nodes { return False; }
        doomed: list[str] = self.get_descendants(cid);
        idx = len(doomed) - 1;
        while idx >= 0 {
            did = doomed[idx];
            if did in self.nodes {
                dn = self.nodes[did];
                destroy dn;
                del self.nodes[did];
            }
            idx -= 1;
        }
        return True;
    }
}

def create_store() -> CategoryStore {
    return CategoryStore();
}

with entry {
    st = create_store();
    st.add_category("electronics", "Electronics", None);
    st.add_category("phones", "Phones", "electronics");
    st.add_category("android", "Android", "phones");
    root spawn DescendantsWalker(claimed={});
}

test "add_category_validations" {
    st = create_store();
    assert st.add_category("electronics", "Electronics", None);
    assert st.add_category("phones", "Phones", "electronics");
    assert not st.add_category("phones", "Dup", None);
    assert not st.add_category("tablet", "Tablet", "missing");
}

test "get_descendants_dfs" {
    st = create_store();
    st.add_category("electronics", "Electronics", None);
    st.add_category("phones", "Phones", "electronics");
    st.add_category("android", "Android", "phones");
    st.add_category("laptops", "Laptops", "electronics");
    got = st.get_descendants("electronics");
    assert got == ["electronics", "phones", "android", "laptops"];
}

test "get_ancestors_chain" {
    st = create_store();
    st.add_category("electronics", "Electronics", None);
    st.add_category("phones", "Phones", "electronics");
    st.add_category("android", "Android", "phones");
    got = st.get_ancestors("android");
    assert got == ["phones", "electronics"];
}

test "unknown_ids_empty" {
    st = create_store();
    assert st.get_descendants("missing") == [];
    assert st.get_ancestors("missing") == [];
    assert not st.remove_category("missing");
}

test "remove_category_cascade" {
    st = create_store();
    st.add_category("electronics", "Electronics", None);
    st.add_category("phones", "Phones", "electronics");
    st.add_category("android", "Android", "phones");
    assert st.remove_category("phones");
    assert st.get_descendants("electronics") == ["electronics"];
    assert st.get_ancestors("android") == [];
    assert not st.remove_category("android");
}

test "leaf_descendants_singleton" {
    st = create_store();
    st.add_category("solo", "Solo", None);
    assert st.get_descendants("solo") == ["solo"];
    assert st.get_ancestors("solo") == [];
}
