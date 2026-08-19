"""Scale a 0-255 color channel by an integer percent using integer division, clamped to 255."""

def _shade(c: int, pct: int) -> int {
    v = c * pct // 100;
    return v if v < 255 else 255;
}

with entry {
    cases = [(235, 100), (235, 85), (80, 70), (60, 45), (250, 100), (255, 100), (300, 100), (0, 85)];
    for (c, p) in cases {
        print(str(c) + "x" + str(p) + " -> " + str(_shade(c, p)));
    }
}
