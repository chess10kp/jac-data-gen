node Pool {}
node Slot { has idx: int, alive: bool; }

walker FreeScan {
    has dead: list = [], result: int = -1;
    can start with Pool entry { visit [-->][?:Slot]; }
    can check with Slot entry {
        if not here.alive { self.dead.append(here.idx); }
    }
    can pick with exit {
        if len(self.dead) > 0 { self.result = min(self.dead); }
    }
}

def free_slot(spec: dict) -> int {
    pool = Pool();
    i = 0;
    for alive in spec["slots"] {
        pool ++> Slot(idx=i, alive=bool(alive));
        i += 1;
    }
    return (pool spawn FreeScan()).result;
}

with entry {
    print(free_slot({'slots': [True, True, False, True, False]}));
}
