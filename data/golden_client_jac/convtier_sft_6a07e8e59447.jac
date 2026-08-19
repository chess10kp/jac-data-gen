node Crate { has weight: int; has flagged: bool = False; }

walker Marker {
    has limit: int;
    can mark with Crate entry {
        if here.weight > self.limit { here.flagged = True; }
        visit [-->];
    }
}

walker Census {
    has count: int = 0;
    can tally with Crate entry {
        if here.flagged { self.count += 1; }
        visit [-->];
    }
}

def flagged_census(spec: dict) -> int {
    nums: list = list(spec["nums"]);
    if not nums { return 0; }
    crates: list = [Crate(weight=int(v)) for v in nums];
    for (a, b) in zip(crates, crates[1:]) { a ++> b; }
    marker = crates[0] spawn Marker(limit=int(spec["limit"]));
    return (crates[0] spawn Census()).count;
}

with entry {
    print(flagged_census({'nums': [4, 9, 1, 7], 'limit': 5}));
}
