node Rung { has load: int; }

walker DepthSum {
    has acc: int = 0;
    has rung_no: int = 0;
    can climb with Rung entry {
        self.rung_no += 1;
        self.acc += here.load * self.rung_no;
        visit [-->];
    }
}

def position_weighted_sum(spec: dict) -> int {
    tail = None;
    for n in reversed(spec["nums"]) {
        rung = Rung(load=int(n));
        if tail is not None { rung ++> tail; }
        tail = rung;
    }
    if tail is None { return 0; }
    climber = tail spawn DepthSum();
    return climber.acc;
}

with entry {
    print(position_weighted_sum({'nums': [2, 3, 4]}));
}
