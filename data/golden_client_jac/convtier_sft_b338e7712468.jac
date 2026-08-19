node Arena { has bound: int; }
node Bullet { has x: int, v: int; }

walker Sweep {
    has bound: int = 0, live: int = 0;
    can start with Arena entry {
        self.bound = here.bound;
        visit [-->][?:Bullet];
    }
    can advance with Bullet entry {
        here.x += here.v;
        if here.x >= 0 and here.x < self.bound { self.live += 1; }
    }
}

def bullet_sweep(spec: dict) -> int {
    arena = Arena(bound=int(spec["arena"]));
    for b in spec["bullets"] {
        arena ++> Bullet(x=int(b["x"]), v=int(b["v"]));
    }
    return (arena spawn Sweep()).live;
}

with entry {
    print(bullet_sweep({'arena': 100, 'bullets': [{'x': 10, 'v': 5}, {'x': 98, 'v': 4}, {'x': 2, 'v': -3}, {'x': 50, 'v': 20}]}));
}
