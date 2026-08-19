node Spawner {}
node Zone { has lo: float; has hi: float; }

walker Respawn {
    has rng: int;
    has vals: list = [];
    can start with Spawner entry { visit [-->]; }
    can draw with Zone entry {
        self.rng = (self.rng * 1103515245 + 12345) % 2147483648;
        r = self.rng / 2147483648.0;
        self.vals.append(round(here.lo + r * (here.hi - here.lo), 6));
        visit [-->];
    }
}

def spawn_points(spec: dict) -> list {
    spawner = Spawner();
    prev = spawner;
    for z in spec["zones"] {
        nxt = Zone(lo=float(z[0]), hi=float(z[1]));
        prev ++> nxt;
        prev = nxt;
    }
    return (spawner spawn Respawn(rng=int(spec["seed"]))).vals;
}

with entry {
    print(spawn_points({'seed': 7, 'zones': [[-14.0, 14.0], [1.0, 5.0], [-16.0, 2.0]]}));
}
