"""
Ancestor chain lookup — one parent hop per step in the Python source.

FreekingDean/gojellyfin#598
"""

node Item {
    has iid: str;
    has name: str = "";
}

edge Parent {}

obj ItemStore {
    has anchor: Item;
    has by_id: dict[str, Item] = {};
}

def build_store(specs: list[list[str]]) -> ItemStore {
    anchor_nd = Item(iid="__anchor__", name="");
    st = ItemStore(anchor=anchor_nd);
    root ++> st.anchor;
    by_id: dict[str, Item] = {};
    for spec in specs {
        iid: str = spec[0];
        name: str = spec[1];
        nd = Item(iid=iid, name=name);
        by_id[iid] = nd;
        st.anchor ++> nd;
    }
    for spec in specs {
        iid: str = spec[0];
        parent_id: str = spec[2];
        if parent_id != "" {
            if iid in by_id {
                if parent_id in by_id {
                    child = by_id[iid];
                    par = by_id[parent_id];
                    child +>:Parent:+> par;
                }
            }
        }
    }
    st.by_id = by_id;
    return st;
}

def item_by_id(st: ItemStore, item_id: str) -> Item | None {
    if item_id in st.by_id {
        return st.by_id[item_id];
    }
    return None;
}

def ancestors(st: ItemStore, item_id: str) -> list[str] {
    out: list[str] = [];
    start = item_by_id(st, item_id);
    if start is None {
        return out;
    }
    w = start spawn AncestorWalker(claimed={}, chain=[]);
    out = w.chain;
    return out;
}

walker AncestorWalker {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can climb with Item entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        ups: list[Item] = [here ->:Parent:->][?:Item];
        if ups {
            par = ups[0];
            self.chain.append(par.iid);
            print("ancestor ", par.iid);
            visit par;
        } else {
            disengage;
        }
    }
}
