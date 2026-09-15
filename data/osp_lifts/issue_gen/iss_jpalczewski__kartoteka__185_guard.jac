"""jpalczewski/kartoteka#185 — dedicated locations table with subtree item queries."""

node Location {
    has cid: str;
    has user_id: str;
    has name: str;
    has kind: str;
    has address: str = "";
}

node Item {
    has iid: str;
}

edge Child {}
edge AtLocation {}

obj Store {
    has graph_root: Location;
    has index: dict[str, Location] = {};
    has items: dict[str, Item] = {};
}

walker SubtreeGather {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can walk with Location entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print("visit", here.cid);
        kids: list[Location] = [here ->:Child:->][?:Location];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

def make_store -> Store {
    anchor = Location(
        cid="__anchor__",
        user_id="",
        name="",
        kind="country",
    );
    st = Store(graph_root=anchor);
    return st;
}

def add_location(
    st: Store,
    loc_id: str,
    user_id: str,
    name: str,
    loc_type: str,
    parent_id: str | None = None,
    address: str | None = None,
) {
    addr: str = "";
    if address is not None {
        addr = address;
    }
    nd = Location(
        cid=loc_id,
        user_id=user_id,
        name=name,
        address=addr,
        kind=loc_type,
    );
    st.index[loc_id] = nd;
    st.graph_root ++> nd;
    if parent_id is not None and parent_id in st.index {
        par = st.index[parent_id] as Location;
        par +>:Child:+> nd;
    }
}

def assign_item(st: Store, item_id: str, location_id: str) {
    if location_id not in st.index {
        return;
    }
    it: Item;
    if item_id in st.items {
        it = st.items[item_id] as Item;
    } else {
        it = Item(iid=item_id);
        st.items[item_id] = it;
        st.graph_root ++> it;
    }
    loc = st.index[location_id] as Location;
    it +>:AtLocation:+> loc;
}

def subtree_ids(st: Store, root_id: str) -> list[str] {
    if root_id not in st.index {
        empty: list[str] = [];
        return empty;
    }
    rt = st.index[root_id] as Location;
    w = rt spawn SubtreeGather();
    print("subtree", root_id, len(w.found));
    return sorted(w.found);
}

def items_in_location(st: Store, root_id: str) -> list[str] {
    loc_ids: list[str] = subtree_ids(st, root_id);
    loc_set: dict[str, bool] = {};
    for lid in loc_ids {
        loc_set[lid] = True;
    }
    hits: list[str] = [];
    for iid in st.items {
        it = st.items[iid] as Item;
        ats: list[Location] = [it ->:AtLocation:->][?:Location];
        for loc in ats {
            if loc.cid in loc_set {
                hits.append(iid);
                break;
            }
        }
    }
    return sorted(hits);
}

def get_location(st: Store, loc_id: str) -> dict[str, str | None] | None {
    if loc_id not in st.index {
        return None;
    }
    nd = st.index[loc_id] as Location;
    pid: str | None = None;
    pars: list[Location] = [nd <-:Child:<-][?:Location];
    if pars {
        pid = pars[0].cid;
    }
    return {
        "id": nd.cid,
        "user_id": nd.user_id,
        "name": nd.name,
        "address": nd.address,
        "type": nd.kind,
        "parent_id": pid,
    };
}

test "make_store_empty" {
    st = make_store();
    assert (len(st.index) == 0);;
}

test "add_and_get_location" {
    st = make_store();
    add_location(st, "loc1", "user1", "Home", "house", None, None);
    got = get_location(st, "loc1");
    assert (got is not None);;
    assert (got["id"] == "loc1");;
    assert (got["parent_id"] is None);;
}

test "subtree_hierarchy" {
    st = make_store();
    add_location(st, "root", "u", "Country", "country");
    add_location(st, "city", "u", "City", "city", "root");
    add_location(st, "room", "u", "Room", "room", "city");
    ids = subtree_ids(st, "city");
    assert (ids == ["city", "room"]);;
}

test "items_in_location" {
    st = make_store();
    add_location(st, "a", "u", "A", "room");
    add_location(st, "b", "u", "B", "room", "a");
    assign_item(st, "item1", "b");
    assign_item(st, "item2", "a");
    assert (items_in_location(st, "a") == ["item1", "item2"]);;
}

test "unknown_location_returns_empty" {
    st = make_store();
    assert (subtree_ids(st, "missing") == []);;
    assert (get_location(st, "missing") is None);;
}

test "parent_id_chain" {
    st = make_store();
    add_location(st, "p", "u", "Parent", "country");
    add_location(st, "c", "u", "Child", "city", "p");
    got = get_location(st, "c");
    assert (got["parent_id"] == "p");;
}
