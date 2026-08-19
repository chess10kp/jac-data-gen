node Cell { has val: int; has seen: bool = False; }

walker MaxC {
    has best: int = -2147483648;
    can step with Cell entry {
        if not here.seen { here.seen = True; if here.val > self.best { self.best = here.val; } visit [-->]; }
    }
}

def max_chain(spec: dict) -> int {
    items: list = list(spec["items"]);
    if len(items) == 0 { return 0; }
    cells: list = [];
    for v in items { cells.append(Cell(val=int(v))); }
    i: int = 0;
    while i < len(cells) - 1 { cells[i] ++> cells[i + 1]; i += 1; }
    w = cells[0] spawn MaxC();
    return w.best;
}

with entry {
    print(max_chain({'items': [3, 1, 4, 1, 5]}));
}
