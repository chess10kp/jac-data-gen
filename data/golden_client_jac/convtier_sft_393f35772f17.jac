node Room { has code: str; has solid: bool; has toured: bool = False; }

walker Tour {
    has rooms: int = 0;
    can roam with Room entry {
        if here.toured { return; }
        here.toured = True;
        self.rooms += 1;
        if here.solid { return; }
        visit [-->(?toured == False)];
    }
}

def count_with_walls(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); walls: list = list(spec["walls"]);
    roster: list = [];
    for a in adj.keys() { roster.append(a); }
    for (a, outs) in adj.items() { for b in outs { if b not in roster { roster.append(b); } } }
    rooms: dict = {nm: Room(code=str(nm), solid=(nm in walls)) for nm in roster};
    for (a, outs) in adj.items() { for b in outs { rooms[a] ++> rooms[b]; } }
    w = Tour() spawn rooms[spec["start"]];
    return w.rooms;
}

with entry {
    print(count_with_walls({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['e'], 'd': [], 'e': []}, 'walls': ['b'], 'start': 'a'}));
}
