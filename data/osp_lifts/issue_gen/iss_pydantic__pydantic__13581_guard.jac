# pydantic/pydantic#13581 — Validators called twice with recursive models.

node ValNode {
    has cid: str;
    has is_empty: bool = False;
}

node AppRoot {}

edge ValChild {}

walker BuildTreeWalker {
    has data: dict = {};

    can grow with ValNode entry {
        print ["build", here.cid];
        if "child" in self.data {
            cr = self.data["child"];
            if cr is not None and isinstance(cr, dict) {
                ch_empty = len(cr) == 0;
                ch = ValNode(cid=here.cid + ":c", is_empty=ch_empty);
                here +>:ValChild:+> ch;
                ch spawn BuildTreeWalker(data=cr);
            }
        }
        disengage;
    }
}

walker ValidateWalker {
    has claimed: dict[str, bool] = {};
    has calls: list[str] = [];

    can validate with ValNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.calls.append("validator called");
        print ["after_validator", here.cid];
        if here.is_empty {
            self.calls.append("validator called");
            print ["prebuilt_reentry", here.cid];
        }
        kids: list[ValNode] = [];
        for ch in [here ->:ValChild:->][?:ValNode] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker RootBootstrapWalker {
    has head: ValNode;

    can boot with AppRoot entry {
        print ["bootstrap"];
        root spawn RootBootstrapWalker(head=self.head);
        self.head spawn ValidateWalker(claimed={});
    }
}

def _mirror_out(data: dict) -> dict {
    out: dict = {};
    if "child" in data {
        cr = data["child"];
        if cr is None {
            out["child"] = None;
        } elif isinstance(cr, dict) {
            out["child"] = _mirror_out(cr);
        }
    }
    return out;
}

def model_validate_node(data: dict | None) -> tuple[dict, list[str]] {
    if data is None {
        data = {};
    }
    nd = ValNode(cid="n0", is_empty=len(data) == 0);
    root ++> nd;
    nd spawn BuildTreeWalker(data=data);
    vw = nd spawn ValidateWalker(claimed={});
    out = _mirror_out(data);
    return (out, vw.calls);
}

def model_validate_outer(data: dict) -> tuple[dict, list[str]] {
    if data is None {
        data = {};
    }
    node_raw = data.get("node");
    if node_raw is None {
        node_raw = {};
    }
    if not isinstance(node_raw, dict) {
        node_raw = {};
    }
    sub = model_validate_node(node_raw);
    return ({"node": sub[0]}, sub[1]);
}

test "empty_root_double_validator" {
    (out, calls) = model_validate_node({});
    assert out == {};
    assert calls == ["validator called", "validator called"];
}

test "none_root_defaults_empty" {
    (out, calls) = model_validate_node(None);
    assert out == {};
    assert calls == ["validator called", "validator called"];
}

test "nested_empty_child_triple_validator" {
    data: dict = {};
    data["child"] = {};
    (out, calls) = model_validate_node(data);
    assert out == {"child": {}};
    assert len(calls) == 3;
    assert calls == ["validator called", "validator called", "validator called"];
}

test "child_none_single_validator" {
    data: dict = {};
    data["child"] = None;
    (out, calls) = model_validate_node(data);
    assert out == {"child": None};
    assert calls == ["validator called"];
}

test "outer_empty_node_wrapper" {
    (out, calls) = model_validate_outer({"node": {}});
    assert out == {"node": {}};
    assert calls == ["validator called", "validator called"];
}

test "shared_child_claim_skip_once" {
    anchor = ValNode(cid="anchor", is_empty=False);
    root ++> anchor;
    shared = ValNode(cid="shared", is_empty=False);
    a = ValNode(cid="a", is_empty=False);
    b = ValNode(cid="b", is_empty=False);
    anchor +>:ValChild:+> a;
    anchor +>:ValChild:+> b;
    a +>:ValChild:+> shared;
    b +>:ValChild:+> shared;
    w = anchor spawn ValidateWalker(claimed={});
    assert len(w.calls) == 3;
    assert w.calls == ["validator called", "validator called", "validator called"];
}
