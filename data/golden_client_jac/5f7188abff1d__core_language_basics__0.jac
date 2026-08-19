"""RL driver (pure-lib): main.na._shade (cheap face shading).

Origin: this_is_jac/main.jac (the `_shade` helper inside the `na {}` block,
isolated from the raylib draw machinery). Deterministic: scales a 0-255 color
channel by an integer percentage using integer division, then clamps the result
to 255. The marked body is the unit the policy must regenerate; the `with entry`
block exercises it on fixed inputs and prints a deterministic projection.
"""

def _shade(c: int, pct: int) -> int {
    # >>>HOLE id="lib_shade_channel" instruction="Implement _shade(c, pct): compute v as c times pct using integer floor division by 100; return v if v is less than 255, otherwise return 255."
    v = c * pct // 100;
    return v if v < 255 else 255;
    # <<<HOLE
}

with entry {
    cases = [(235, 100), (235, 85), (80, 70), (60, 45), (250, 100), (255, 100), (300, 100), (0, 85)];
    for (c, p) in cases {
        print(str(c) + "x" + str(p) + " -> " + str(_shade(c, p)));
    }
}
