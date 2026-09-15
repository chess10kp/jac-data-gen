"""microsoft/Power-Fx#726 — Serializer recursive object handling."""

node Record {
    has cid: str;
    has label: str = "";
}

edge Ref {}

walker SerializeWalker {
    has claimed: dict[str, bool] = {};
    has fragments: dict[str, str] = {};

    can step with Record entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        parts: list[str] = [];
        parts.append("\"label\":\"" + here.label + "\"");
        kids: list[Record] = [here ->:Ref:->][?:Record];
        idx: int = 0;
        for ch in kids {
            parts.append("\"r" + str(idx) + "\":\"$ref:" + ch.cid + "\"");
            idx += 1;
            visit :0: [ch];
        }
        body: str = "";
        for i in range(len(parts)) {
            if i > 0 { body += ","; }
            body += parts[i];
        }
        self.fragments[here.cid] = "{" + body + "}";
        print("serialize " + here.cid);
    }
}

walker FindWalker {
    has target_cid: str;
    has found: Record | None = None;
    has claimed: dict[str, bool] = {};

    can step with Record entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("find " + here.cid);
        if here.cid == self.target_cid {
            self.found = here;
            disengage;
        }
        kids: list[Record] = [here ->:Ref:->][?:Record];
        if kids {
            visit :0: kids;
        }
    }
}

def make_record(cid: str, label: str) -> Record {
    nd = Record(cid=cid, label=label);
    root ++> nd;
    return nd;
}

def link_ref(parent: Record, child: Record) -> None {
    parent +>:Ref:+> child;
}

def serialize_records(graph_root: Record) -> str {
    w = graph_root spawn SerializeWalker();
    keys: list[str] = [];
    for k in w.fragments {
        keys.append(k);
    }
    keys = sorted(keys);
    out: str = "{";
    for i in range(len(keys)) {
        if i > 0 { out += ","; }
        k = keys[i];
        out += "\"" + k + "\":" + w.fragments[k];
    }
    out += "}";
    return out;
}

def find_by_cid(graph_root: Record, target_cid: str) -> Record | None {
    fw = graph_root spawn FindWalker(target_cid=target_cid);
    return fw.found;
}

test "unknown_cid_returns_none" {
    nd = make_record("u1", "U");
    got = find_by_cid(nd, "nope");
    assert got is None;
}

test "solo_record_no_refs" {
    nd = make_record("s1", "solo");
    out = serialize_records(nd);
    assert out == "{\"s1\":{\"label\":\"solo\"}}";
}

test "self_loop_claimed_once" {
    nd = make_record("sl", "loop");
    link_ref(nd, nd);
    out = serialize_records(nd);
    assert out == "{\"sl\":{\"label\":\"loop\",\"r0\":\"$ref:sl\"}}";
}

test "cycle_ab_claimed_once_each" {
    a = make_record("ca", "A");
    b = make_record("cb", "B");
    link_ref(a, b);
    link_ref(b, a);
    out = serialize_records(a);
    assert out == "{\"ca\":{\"label\":\"A\",\"r0\":\"$ref:cb\"},\"cb\":{\"label\":\"B\",\"r0\":\"$ref:ca\"}}";
}

test "find_existing_cid" {
    nd = make_record("fx", "found");
    got = find_by_cid(nd, "fx");
    assert got is not None;
    assert got.cid == "fx";
}

test "shared_child_single_fragment" {
    parent = make_record("p1", "P");
    child = make_record("c1", "C");
    link_ref(parent, child);
    out = serialize_records(parent);
    assert out == "{\"c1\":{\"label\":\"C\"},\"p1\":{\"label\":\"P\",\"r0\":\"$ref:c1\"}}";
}
