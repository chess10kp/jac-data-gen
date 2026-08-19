node Bead { has amt: int; }

walker Taker {
    has quota: int;
    has taken: int = 0;
    has acc: int = 0;
    can grab with Bead entry {
        if self.taken >= self.quota { disengage; }
        self.acc += here.amt;
        self.taken += 1;
        visit [-->];
    }
}

def sum_first_k(spec: dict) -> int {
    seq: list = list(spec["items"]);
    if not seq { return 0; }
    head = Bead(amt=int(seq[0]));
    tail = head;
    for v in seq[1:] {
        nxt = Bead(amt=int(v));
        tail ++> nxt;
        tail = nxt;
    }
    w = head spawn Taker(quota=int(spec["k"]));
    return w.acc;
}

with entry {
    print(sum_first_k({'items': [5, 2, 9, 4], 'k': 2}));
}
