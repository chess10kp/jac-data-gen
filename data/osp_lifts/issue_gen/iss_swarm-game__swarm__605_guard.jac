"""swarm-game/swarm#605 — mutual even/odd bindings lifted to paired walkers."""

node Chain {
    has cid: str;
    has val: int;
}

edge Step {}

obj mutual_store {
    has nodes: dict[str, Chain] = {};
}

def _clear() -> None {
    mutual_store.nodes = {};
}

def find_node(cid: str) -> Chain | None {
    if cid in mutual_store.nodes {
        return mutual_store.nodes[cid];
    }
    return None;
}

def _mk(cid: str, val: int) -> Chain {
    nd = Chain(cid=cid, val=val);
    mutual_store.nodes[cid] = nd;
    root ++> nd;
    return nd;
}

def _link(a: Chain, b: Chain) -> None {
    a +>:Step:+> b;
}

def _pick_next(here: Chain, kids: list[Chain]) -> Chain | None {
    nxt: Chain | None = None;
    for ch in kids {
        if ch.val == here.val - 1 {
            if nxt == None {
                nxt = ch;
            } elif ch.cid < nxt.cid {
                nxt = ch;
            }
        }
    }
    return nxt;
}

def build_chain(n: int) -> str {
    _clear();
    if n < 0 {
        return "";
    }
    for i in range(n + 1) {
        cid: str = "c" + str(i);
        _mk(cid, i);
    }
    j: int = n;
    while j > 0 {
        hi = mutual_store.nodes["c" + str(j)] as Chain;
        lo = mutual_store.nodes["c" + str(j - 1)] as Chain;
        _link(hi, lo);
        j -= 1;
    }
    return "c" + str(n);
}

def build_diamond(n: int) -> str {
    _clear();
    if n < 2 {
        return build_chain(n);
    }
    top = _mk("top", n);
    left = _mk("left", n - 1);
    right = _mk("right", n - 1);
    for i in range(n - 1) {
        cid: str = "c" + str(i);
        _mk(cid, i);
    }
    k: int = n - 1;
    while k > 0 {
        hi = mutual_store.nodes["c" + str(k)] as Chain;
        lo = mutual_store.nodes["c" + str(k - 1)] as Chain;
        _link(hi, lo);
        k -= 1;
    }
    mid = mutual_store.nodes["c" + str(n - 1)] as Chain;
    _link(top, left);
    _link(top, right);
    _link(left, mid);
    _link(right, mid);
    loop_tgt = mutual_store.nodes["c" + str(n - 2)] as Chain;
    _link(mid, loop_tgt);
    return top.cid;
}

def even(n: int) -> bool {
    if n < 0 {
        return False;
    }
    head_id: str = build_chain(n);
    if head_id == "" {
        return True;
    }
    if head_id not in mutual_store.nodes {
        return False;
    }
    start = mutual_store.nodes[head_id] as Chain;
    ew = start spawn EvenWalk(claimed={});
    print("even", n, ew.out);
    return ew.out;
}

def odd(n: int) -> bool {
    if n < 0 {
        return False;
    }
    head_id: str = build_chain(n);
    if head_id == "" {
        return False;
    }
    if head_id not in mutual_store.nodes {
        return False;
    }
    start = mutual_store.nodes[head_id] as Chain;
    ow = start spawn OddWalk(claimed={});
    print("odd", n, ow.out);
    return ow.out;
}

walker EvenWalk {
    has claimed: dict[str, bool] = {};
    has out: bool = False;

    can go with Chain entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.val == 0 {
            self.out = True;
            print("EvenWalk", here.cid, True);
            disengage;
        }
        kids: list[Chain] = [here ->:Step:->][?:Chain];
        nxt = _pick_next(here, kids);
        if nxt == None {
            self.out = False;
            disengage;
        } else {
            ow = nxt spawn OddWalk(claimed=self.claimed);
            self.out = ow.out;
            print("EvenWalk", here.cid, self.out);
            disengage;
        }
    }
}

walker OddWalk {
    has claimed: dict[str, bool] = {};
    has out: bool = False;

    can go with Chain entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.val == 0 {
            self.out = False;
            print("OddWalk", here.cid, False);
            disengage;
        }
        kids: list[Chain] = [here ->:Step:->][?:Chain];
        nxt = _pick_next(here, kids);
        if nxt == None {
            self.out = False;
            disengage;
        } else {
            ew = nxt spawn EvenWalk(claimed=self.claimed);
            self.out = not ew.out;
            print("OddWalk", here.cid, self.out);
            disengage;
        }
    }
}

walker LetrecSeed {
    has claimed: dict[str, bool] = {};
    has out: bool = False;

    can seed with Chain entry {
        ew = here spawn EvenWalk(claimed=self.claimed);
        self.out = ew.out;
        print("LetrecSeed", self.out);
        disengage;
    }
}

test "even_zero" {
    assert even(0) == True;;
}

test "odd_zero" {
    assert odd(0) == False;;
}

test "even_one" {
    assert even(1) == False;;
}

test "odd_one" {
    assert odd(1) == False;;
}

test "odd_two" {
    assert odd(2) == True;;
}

test "letrec_seed" {
    head_id = build_chain(2);
    start = mutual_store.nodes[head_id] as Chain;
    w = start spawn LetrecSeed(claimed={});
    assert w.out == even(2);;
}
