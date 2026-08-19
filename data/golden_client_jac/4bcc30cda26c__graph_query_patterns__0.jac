"""RL driver (pure-lib): main.update_bullets (advance bullets, resolve hits, tally score).

Origin: this_is_jac/raylib_shooter/web/main.jac (the update_bullets logic, isolated from
any io/time/graph machinery). Deterministic: a stationary bullet overlapping an alive
target makes the collision fire exactly once, and the respawn it triggers uses the fixed
rng seed; all printed floats are rounded to 6 dp. The marked body is the unit the policy
must regenerate; the with entry block exercises it on fixed inputs and prints a
deterministic projection.
"""

glob rng: int = 987654321,
     score: int = 0;

obj Target {
    has x: float,
        y: float,
        z: float,
        base_y: float,
        phase: float,
        alive: bool;
}

obj Bullet {
    has x: float,
        y: float,
        z: float,
        vx: float,
        vy: float,
        vz: float,
        life: float;
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

"""(Re)place a target somewhere in the arena in front of the player (dependency, not the target)."""
def respawn(t: Target) {
    t.x = rand_range(-14.0, 14.0);
    t.base_y = rand_range(1.0, 5.0);
    t.z = rand_range(-16.0, 2.0);
    t.phase = rand_range(0.0, 6.28);
    t.y = t.base_y;
    t.alive = True;
}

def update_bullets(bullets: list[Bullet], targets: list[Target], step: float) {
    # >>>HOLE id="lib_update_bullets_score" instruction="Advance bullets, resolve hits against targets, and tally score. Use a global score. Loop over every bullet by index. For each bullet whose life is > 0, advance its position by its velocity times step (x += vx*step, etc.) and decay its life by step. Then loop over every target by index; for each target that is alive, compute the component differences between the bullet and target positions (dx, dy, dz). If the sum of their squares is less than 1.4, register a hit: mark the target not alive, set the bullet's life to 0.0, increment the global score by 1, and respawn the target. Continue scanning all targets, then all bullets."
    global score;
    bi = 0;
    while bi < len(bullets) {
        b = bullets[bi];
        if b.life > 0.0 {
            b.x += b.vx * step;
            b.y += b.vy * step;
            b.z += b.vz * step;
            b.life -= step;
            ti = 0;
            while ti < len(targets) {
                t = targets[ti];
                if t.alive {
                    ddx = b.x - t.x;
                    ddy = b.y - t.y;
                    ddz = b.z - t.z;
                    if ddx * ddx + ddy * ddy + ddz * ddz < 1.4 {
                        t.alive = False;
                        b.life = 0.0;
                        score += 1;
                        respawn(t);
                    }
                }
                ti += 1;
            }
        }
        bi += 1;
    }
    # <<<HOLE
}

with entry {
    bullets = [
        Bullet(x=0.0, y=0.0, z=0.0, vx=0.0, vy=0.0, vz=0.0, life=1.0),
        Bullet(x=50.0, y=50.0, z=50.0, vx=0.0, vy=0.0, vz=0.0, life=1.0)
    ];
    targets = [
        Target(x=0.0, y=0.0, z=0.0, base_y=0.0, phase=0.0, alive=True),
        Target(x=-50.0, y=-50.0, z=-50.0, base_y=0.0, phase=0.0, alive=True)
    ];
    update_bullets(bullets, targets, 0.016);
    print(
        str(score) + " " + str(round(targets[0].x, 6)) + " "
        + str(round(targets[0].z, 6)) + " " + str(round(bullets[0].life, 6)) + " "
        + str(targets[0].alive)
    );
}
