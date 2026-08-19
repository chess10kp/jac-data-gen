node Cell { has idx: int; has val: int; }

walker NegProbe {
    has found: int = -1;
    can seek with Cell entry {
        if self.found == -1 {
            if here.val < 0 { self.found = here.idx; }
            else { visit [-->]; }
        }
    }
}

walker TailTally {
    has count: int = 0;
    can tally with Cell entry {
        self.count += 1;
        visit [-->];
    }
}

def tail_after_first_negative(spec: dict) -> int {
    nums: list = list(spec["nums"]);
    if not nums { return 0; }
    cells: list = [];
    for i in range(len(nums)) { cells.append(Cell(idx=i, val=int(nums[i]))); }
    for (a, b) in zip(cells, cells[1:]) { a ++> b; }
    probe = cells[0] spawn NegProbe();
    if probe.found == -1 { return 0; }
    return (cells[probe.found] spawn TailTally()).count;
}

with entry {
    print(tail_after_first_negative({'nums': [3, -1, 4, 5]}));
}
