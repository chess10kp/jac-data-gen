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
