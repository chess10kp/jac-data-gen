"""Bobbing target height: base_y + 0.4 * jsin(world_t * 1.5 + phase), using pure-Jac trig."""

def jcos(a: float) -> float {
    twopi = 6.283185307179586;
    pi = 3.141592653589793;
    while a > pi {
        a -= twopi;
    }
    while a < -pi {
        a += twopi;
    }
    x2 = a * a;
    x4 = x2 * x2;
    x6 = x4 * x2;
    x8 = x4 * x4;
    x10 = x8 * x2;
    x12 = x8 * x4;
    return 1.0 - x2 / 2.0 + x4 / 24.0 - x6 / 720.0 + x8 / 40320.0 - x10 / 3628800.0 + x12 / 479001600.0;
}

def jsin(a: float) -> float {
    return jcos(a - 1.5707963267948796);
}

def hover_y(base_y: float, world_t: float, phase: float) -> float {
    return base_y + 0.4 * jsin(world_t * 1.5 + phase);
}

with entry {
    cases = [(2.0, 0.0, 0.0), (3.0, 1.25, 0.5), (1.0, 4.0, 6.28), (5.0, 10.0, 3.14)];
    for c in cases {
        print(str(round(hover_y(c[0], c[1], c[2]), 6)));
    }
}
