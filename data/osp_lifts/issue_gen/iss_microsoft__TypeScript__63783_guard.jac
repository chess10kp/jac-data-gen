# OSP lift: microsoft/TypeScript#63783 — bounded recursive seq rewrite / union.

node Hub {
    has counter: int = 0;
}

node SeqNode {
    has cid: str;
    has kind: str;
}

edge L1 {}
edge L2 {}
edge R1 {}
edge R2 {}

def next_cid(hub: Hub) -> str {
    hub.counter += 1;
    return "n" + str(hub.counter);
}

def rotate_kind(kind: str) -> str {
    if kind == "A" {
        return "B";
    }
    if kind == "B" {
        return "C";
    }
    if kind == "C" {
        return "D";
    }
    return "A";
}

def leaf_labels(kind: str) -> list[str] {
    out: list[str] = [];
    if kind == "A" {
        out.append("s1");
        out.append("s2");
        out.append("s3");
    } elif kind == "B" {
        out.append("n1");
        out.append("n2");
        out.append("n3");
    } elif kind == "C" {
        out.append("n1s1");
        out.append("n2s2");
    } else {
        out.append("s1n1");
        out.append("s2n2");
    }
    return out;
}

def make_leaf(hub: Hub, kind: str) -> str {
    cid = next_cid(hub);
    nd = SeqNode(cid=cid, kind=kind);
    root ++> nd;
    return cid;
}

def make_branch(hub: Hub, l1: str, l2: str, r1: str, r2: str) -> str {
    cid = next_cid(hub);
    br = SeqNode(cid=cid, kind="Branch");
    root ++> br;
    w = root spawn LinkChild(needle=l1, slot="L1", branch=br, claimed={});
    w = root spawn LinkChild(needle=l2, slot="L2", branch=br, claimed={});
    w = root spawn LinkChild(needle=r1, slot="R1", branch=br, claimed={});
    w = root spawn LinkChild(needle=r2, slot="R2", branch=br, claimed={});
    return cid;
}

walker LinkChild {
    has needle: str;
    has slot: str;
    has branch: SeqNode;
    has claimed: dict[str, bool] = {};

    can link with SeqNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.needle {
            if self.slot == "L1" {
                self.branch +>:L1:+> here;
            } elif self.slot == "L2" {
                self.branch +>:L2:+> here;
            } elif self.slot == "R1" {
                self.branch +>:R1:+> here;
            } else {
                self.branch +>:R2:+> here;
            }
            print("linked ", self.slot, " ", here.cid);
            disengage;
        }
        nxt: list[SeqNode] = [];
        for ch in [here ->:L1:->][?:SeqNode] {
            nxt.append(ch);
        }
        for ch in [here ->:L2:->][?:SeqNode] {
            nxt.append(ch);
        }
        for ch in [here ->:R1:->][?:SeqNode] {
            nxt.append(ch);
        }
        for ch in [here ->:R2:->][?:SeqNode] {
            nxt.append(ch);
        }
        visit :0: nxt else {
            disengage;
        }
    }
}

walker Finder {
    has needle: str;
    has found: bool = False;
    has node_ref: SeqNode | None = None;
    has claimed: dict[str, bool] = {};

    can seek with SeqNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.needle {
            self.found = True;
            self.node_ref = here;
            print("finder hit ", here.cid);
            disengage;
        }
        nxt: list[SeqNode] = [];
        for ch in [here ->:L1:->][?:SeqNode] {
            nxt.append(ch);
        }
        for ch in [here ->:L2:->][?:SeqNode] {
            nxt.append(ch);
        }
        for ch in [here ->:R1:->][?:SeqNode] {
            nxt.append(ch);
        }
        for ch in [here ->:R2:->][?:SeqNode] {
            nxt.append(ch);
        }
        visit :0: nxt else {
            disengage;
        }
    }
}

def find_seq(node_id: str) -> SeqNode | None {
    w = root spawn Finder(needle=node_id, claimed={});
    if w.found {
        return w.node_ref;
    }
    return None;
}

def expand_leaf(hub: Hub, kind: str) -> str {
    k1 = kind;
    k2 = rotate_kind(k1);
    k3 = rotate_kind(k2);
    k4 = rotate_kind(k3);
    a = make_leaf(hub, k1);
    b = make_leaf(hub, k2);
    c = make_leaf(hub, k3);
    d = make_leaf(hub, k4);
    return make_branch(hub, a, b, c, d);
}

walker Rewriter {
    has hub: Hub;
    has memo: dict[str, str] = {};
    has claimed: dict[str, bool] = {};

    can rewrite with SeqNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        kids: list[SeqNode] = [];
        if here.kind == "Branch" {
            for ch in [here ->:L1:->][?:SeqNode] {
                kids.append(ch);
            }
            for ch in [here ->:L2:->][?:SeqNode] {
                kids.append(ch);
            }
            for ch in [here ->:R1:->][?:SeqNode] {
                kids.append(ch);
            }
            for ch in [here ->:R2:->][?:SeqNode] {
                kids.append(ch);
            }
        }
        visit kids;
        new_id: str = "";
        if here.kind != "Branch" {
            new_id = expand_leaf(self.hub, here.kind);
        } else {
            l1s: list[SeqNode] = [here ->:L1:->][?:SeqNode];
            l2s: list[SeqNode] = [here ->:L2:->][?:SeqNode];
            r1s: list[SeqNode] = [here ->:R1:->][?:SeqNode];
            r2s: list[SeqNode] = [here ->:R2:->][?:SeqNode];
            nl1 = self.memo[l1s[0].cid];
            nl2 = self.memo[l2s[0].cid];
            nr1 = self.memo[r1s[0].cid];
            nr2 = self.memo[r2s[0].cid];
            new_id = make_branch(self.hub, nl1, nl2, nr1, nr2);
        }
        self.memo[here.cid] = new_id;
        print("rewrote ", here.cid, " -> ", new_id);
    }
}

def rewrite_once(hub: Hub, node_id: str) -> str {
    nd = find_seq(node_id);
    if nd is None {
        return node_id;
    }
    wk = nd spawn Rewriter(hub=hub, memo={}, claimed={});
    return wk.memo[node_id];
}

def apply_rewrite(hub: Hub, node_id: str, steps: int) -> str {
    cur = node_id;
    i = 0;
    while i < steps {
        cur = rewrite_once(hub, cur);
        i += 1;
    }
    return cur;
}

def cross_concat(a: list[str], b: list[str]) -> list[str] {
    out: list[str] = [];
    for x in a {
        for y in b {
            out.append(x + y);
        }
    }
    return sorted(out);
}

def seq_union(hub: Hub, node_id: str) -> list[str] {
    _ = hub.counter;
    nd = find_seq(node_id);
    if nd is None {
        return [];
    }
    return leaf_labels(nd.kind);
}

with entry {
    hub = Hub();
    root ++> hub;
    a = make_leaf(hub, "A");
    out = rewrite_once(hub, a);
    print("demo rewrite ", a, " -> ", out);
    w = root spawn Finder(needle=a, claimed={});
    print("finder demo found ", w.found);
}

test "leaf_labels_a" {
    assert (sorted(leaf_labels("A")) == ["s1", "s2", "s3"]);
}

test "cross_concat_sorted" {
    assert (cross_concat(["b", "a"], ["y", "x"]) == ["ax", "ay", "bx", "by"]);
}

test "find_seq_hit" {
    hub = Hub();
    root ++> hub;
    cid = make_leaf(hub, "A");
    nd = find_seq(cid);
    assert (nd is not None);
    assert (nd.kind == "A");
}

test "rewrite_once_expands_leaf" {
    hub = Hub();
    root ++> hub;
    cid = make_leaf(hub, "A");
    out = rewrite_once(hub, cid);
    assert (out != cid);
    br = find_seq(out);
    assert (br is not None);
    assert (br.kind == "Branch");
}

test "apply_rewrite_bounded" {
    hub = Hub();
    root ++> hub;
    cid = make_leaf(hub, "B");
    out = apply_rewrite(hub, cid, 2);
    assert (out != cid);
    assert (find_seq(out) is not None);
}

test "seq_union_unknown" {
    hub = Hub();
    root ++> hub;
    assert (seq_union(hub, "missing") == []);
}
