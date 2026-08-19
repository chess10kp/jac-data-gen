node Crate { has load: int; }

walker Hauler {
    has carried: int = 0;
    can lift with Crate entry {
        if here.load < 0 { disengage; }
        self.carried += here.load;
        visit [-->];
    }
}

def sum_until_negative(spec: dict) -> int {
    stuff: list = list(spec["items"]);
    if not stuff { return 0; }
    crates: list = [Crate(load=int(x)) for x in stuff];
    j: int = len(crates) - 1;
    while j > 0 { crates[j - 1] ++> crates[j]; j -= 1; }
    w = Hauler() spawn crates[0];
    return w.carried;
}

with entry {
    print(sum_until_negative({'items': [4, 6, -2, 50]}));
}
