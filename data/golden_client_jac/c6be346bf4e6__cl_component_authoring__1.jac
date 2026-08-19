"""RL driver (pure-lib): raylib_shim._cur (select the current matrix by rlgl mode).

Origin: this_is_jac/raylib_shim.cl.jac (the _cur helper, isolated from io/time/graph/render
machinery). Deterministic: a pure conditional over a minimal inlined Shim object with fixed fields,
no Math/host/rng. The marked body is the unit the policy must regenerate; the with entry block
exercises both branches on fixed inputs and prints a deterministic projection.
"""

obj Shim {
    has proj: list = [],
        mv: list = [],
        mode: int = 0x1700;
}

def _cur(sh: any) -> list {
    # >>>HOLE id="lib_cur_matrix" instruction="Return the shim's current matrix: if sh.mode equals 0x1701 (projection mode) return sh.proj, otherwise return sh.mv. Use a single conditional expression."
    return sh.proj if sh.mode == 0x1701 else sh.mv;
    # <<<HOLE
}

with entry {
    a = Shim(proj=[1.0, 2.0], mv=[3.0, 4.0], mode=0x1701);
    b = Shim(proj=[1.0, 2.0], mv=[3.0, 4.0], mode=0x1700);
    print(str(_cur(a)));
    print(str(_cur(b)));
}
