node Lamp {}
node Room { has pct: int; }

walker Shade {
    has value: int;
    can start with Lamp entry { visit [-->]; }
    can dim with Room entry {
        v = self.value * here.pct // 100;
        self.value = v if v < 255 else 255;
        visit [-->];
    }
}

def shade_corridor(spec: dict) -> int {
    lamp = Lamp();
    prev = lamp;
    for p in spec["pcts"] { nxt = Room(pct=int(p)); prev ++> nxt; prev = nxt; }
    return (lamp spawn Shade(value=int(spec["channel"]))).value;
}

with entry {
    print(shade_corridor({'channel': 235, 'pcts': [85, 70]}));
}
