node Cell { has val: int; has seen: bool = False; }

walker CntC {
    has count: int = 0;
    can step with Cell entry {
        if not here.seen { here.seen = True; self.count += 1; visit [-->]; }
    }
}

def count_chain(spec: dict) -> int {
    items: list = list(spec["items"]);
    if len(items) == 0 { return 0; }
    cells: list = [];
    for v in items { cells.append(Cell(val=int(v))); }
    i: int = 0;
    while i < len(cells) - 1 { cells[i] ++> cells[i + 1]; i += 1; }
    w = cells[0] spawn CntC();
    return w.count;
}

with entry {
    print(count_chain({'items': [3, 1, 4, 1, 5]}));
}
