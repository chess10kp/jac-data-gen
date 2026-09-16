"""Stable ordered collection with stable indices — apple/swift-collections#103."""

node Element {
    has sid: int;
    has val: str;
    has live: bool = True;
}

edge Dep {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has vals: list[str] = [];

    can step with Element entry {
        skey = str(here.sid);
        if skey in self.claimed { skip; }
        self.claimed[skey] = True;
        if here.live {
            self.vals.append(here.val);
        }
        kids: list[object] = [];
        for ch in [here ->:Dep:->][?:Element] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker DependentCollect {
    has claimed: dict[str, bool] = {};
    has doomed: list[int] = [];

    can step with Element entry {
        skey = str(here.sid);
        if skey in self.claimed { skip; }
        self.claimed[skey] = True;
        if !here.live {
            disengage;
        }
        self.doomed.append(here.sid);
        kids: list[object] = [];
        for ch in [<-:Dep:<-][?:Element] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def make_bag -> dict {
    bag: dict = {};
    bag["next"] = 1;
    ord: list[int] = [];
    bag["order"] = ord;
    mp: dict[str, Element] = {};
    bag["map"] = mp;
    return bag;
}

def bag_append(bag: dict, val: str) -> int {
    nxt = bag["next"];
    bag["next"] = nxt + 1;
    el = Element(sid=nxt, val=val, live=True);
    root ++> el;
    mp = bag["map"] as dict[str, Element];
    mp[str(nxt)] = el;
    bag["map"] = mp;
    ord = bag["order"] as list[int];
    ord.append(nxt);
    bag["order"] = ord;
    return nxt;
}

def bag_get(bag: dict, sid: int) -> str | None {
    mp = bag["map"] as dict[str, Element];
    key = str(sid);
    if !(key in mp) {
        return None;
    }
    el = mp[key] as Element;
    if !el.live {
        return None;
    }
    return el.val;
}

def bag_remove(bag: dict, sid: int) -> bool {
    mp = bag["map"] as dict[str, Element];
    key = str(sid);
    if !(key in mp) {
        return False;
    }
    el = mp[key] as Element;
    if !el.live {
        return False;
    }
    el.live = False;
    return True;
}

def bag_first_of(bag: dict, val: str) -> int | None {
    ord = bag["order"] as list[int];
    mp = bag["map"] as dict[str, Element];
    for sid in ord {
        key = str(sid);
        if key in mp {
            el = mp[key] as Element;
            if el.live and el.val == val {
                return sid;
            }
        }
    }
    return None;
}

def bag_link(bag: dict, src: int, dst: int) -> bool {
    mp = bag["map"] as dict[str, Element];
    skey = str(src);
    dkey = str(dst);
    if !(skey in mp) or !(dkey in mp) {
        return False;
    }
    a = mp[skey] as Element;
    b = mp[dkey] as Element;
    if !a.live or !b.live {
        return False;
    }
    a +>:Dep:+> b;
    return True;
}

def bag_ordered(bag: dict) -> list[str] {
    out: list[str] = [];
    ord = bag["order"] as list[int];
    mp = bag["map"] as dict[str, Element];
    for sid in ord {
        key = str(sid);
        if key in mp {
            el = mp[key] as Element;
            if el.live {
                out.append(el.val);
            }
        }
    }
    return out;
}

def bag_cascade_remove(bag: dict, sid: int) -> list[str] {
    mp = bag["map"] as dict[str, Element];
    key = str(sid);
    if !(key in mp) {
        return [];
    }
    start = mp[key] as Element;
    if !start.live {
        return [];
    }
    w = start spawn DependentCollect(claimed={});
    doomed = w.doomed;
    vals: list[str] = [];
    for dsid in doomed {
        dkey = str(dsid);
        if dkey in mp {
            el = mp[dkey] as Element;
            if el.live {
                vals.append(el.val);
                el.live = False;
            }
        }
    }
    vals.sort();
    return vals;
}

def run_probe -> list[str] {
    bag = make_bag();
    a = bag_append(bag, "a");
    b = bag_append(bag, "b");
    c = bag_append(bag, "c");
    bag_link(bag, a, c);
    bag_link(bag, b, c);
    mp = bag["map"] as dict[str, Element];
    el = mp[str(a)] as Element;
    w = el spawn ReachWalk(claimed={});
    print(w.vals);
    return w.vals;
}

test "append_and_order" {
    bag = make_bag();
    bag_append(bag, "a");
    bag_append(bag, "b");
    assert bag_ordered(bag) == ["a", "b"];
}

test "get_missing_and_dead" {
    bag = make_bag();
    sid = bag_append(bag, "x");
    assert bag_get(bag, sid) == "x";
    assert bag_get(bag, 9999) is None;
    bag_remove(bag, sid);
    assert bag_get(bag, sid) is None;
    assert bag_remove(bag, sid) is False;
}

test "first_of_stable" {
    bag = make_bag();
    bag_append(bag, "a");
    s2 = bag_append(bag, "b");
    bag_append(bag, "a");
    assert bag_first_of(bag, "b") == s2;
    assert bag_first_of(bag, "z") is None;
}

test "link_and_reach" {
    bag = make_bag();
    a = bag_append(bag, "a");
    b = bag_append(bag, "b");
    c = bag_append(bag, "c");
    assert bag_link(bag, a, c) is True;
    assert bag_link(bag, b, c) is True;
    assert bag_link(bag, 99, c) is False;
    mp = bag["map"] as dict[str, Element];
    el = mp[str(a)] as Element;
    w = el spawn ReachWalk(claimed={});
    assert w.vals == ["a", "c"];
}

test "cascade_from_hub" {
    bag = make_bag();
    a = bag_append(bag, "a");
    b = bag_append(bag, "b");
    c = bag_append(bag, "c");
    bag_link(bag, a, c);
    bag_link(bag, b, c);
    out = bag_cascade_remove(bag, c);
    assert out == ["a", "b", "c"];
    assert bag_ordered(bag) == [];
}

test "cascade_from_leaf" {
    bag = make_bag();
    a = bag_append(bag, "a");
    c = bag_append(bag, "c");
    bag_link(bag, a, c);
    out = bag_cascade_remove(bag, a);
    assert out == ["a"];
    assert bag_get(bag, c) == "c";
}
