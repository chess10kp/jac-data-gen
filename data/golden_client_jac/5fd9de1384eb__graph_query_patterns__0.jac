"""RL driver (pure-lib): main.respawn ((re)place a target in the arena via seeded rng).

Origin: this_is_jac/raylib_shooter/web/main.jac (the respawn logic, isolated from any
io/time/graph machinery). Deterministic: the fixed rng seed makes the four LCG draws
identical every run, and all printed floats are rounded to 6 dp. The marked body is the
unit the policy must regenerate; the with entry block exercises it on fixed inputs and
prints a deterministic projection.
"""

glob rng: int = 987654321;

obj Target {
    has x: float,
        y: float,
        z: float,
        base_y: float,
        phase: float,
        alive: bool;
}

"""Uniform pseudo-random float in [0, 1) via a 31-bit LCG."""
def rand01 -> float {
    global rng;
    rng = (rng * 1103515245 + 12345) % 2147483648;
    return float(rng) / 2147483648.0;
}

"""Random float in [lo, hi)."""
def rand_range(lo: float, hi: float) -> float {
    return lo + rand01() * (hi - lo);
}

def respawn(t: Target) {
    # >>>HOLE id="lib_respawn_target" instruction="Place the target somewhere random in the arena in front of the player. Set x to a random value in [-14, 14), base_y to a random value in [1, 5), z to a random value in [-16, 2), and phase to a random value in [0, 6.28), each via rand_range. Then set the target's y equal to its base_y, and mark it alive (True)."
    t.x = rand_range(-14.0, 14.0);
    t.base_y = rand_range(1.0, 5.0);
    t.z = rand_range(-16.0, 2.0);
    t.phase = rand_range(0.0, 6.28);
    t.y = t.base_y;
    t.alive = True;
    # <<<HOLE
}

with entry {
    t = Target(x=0.0, y=0.0, z=0.0, base_y=0.0, phase=0.0, alive=False);
    respawn(t);
    print(
        str(round(t.x, 6)) + " " + str(round(t.base_y, 6)) + " "
        + str(round(t.z, 6)) + " " + str(round(t.phase, 6)) + " "
        + str(round(t.y, 6)) + " " + str(t.alive)
    );
}
