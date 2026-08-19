"""Yaw (degrees) -> forward/right basis vectors on the XZ plane, using pure-Jac trig."""

glob DEG2RAD: float = 0.017453292519943295;

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

def yaw_basis(yaw: float) -> list[float] {
    yaw_r = yaw * DEG2RAD;
    fwd_x = -jsin(yaw_r);
    fwd_z = -jcos(yaw_r);
    rgt_x = jcos(yaw_r);
    rgt_z = -jsin(yaw_r);
    return [fwd_x, fwd_z, rgt_x, rgt_z];
}

with entry {
    yaws = [0.0, 45.0, 90.0, 135.0, 180.0, 270.0];
    for yaw in yaws {
        b = yaw_basis(yaw);
        for v in b {
            print(str(round(v, 6)));
        }
    }
}
