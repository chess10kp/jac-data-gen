"""rlgl-style matrix shim: store the current matrix into proj (mode 0x1701) or mv (otherwise)."""

obj Shim {
    has proj: list = [],
        mv: list = [],
        mode: int = 0x1700;
}

def _setcur(sh: any, m: list) {
    if sh.mode == 0x1701 {
        sh.proj = m;
    } else {
        sh.mv = m;
    }
}

with entry {
    a = Shim(proj=[], mv=[], mode=0x1701);
    _setcur(a, [9.0, 8.0]);
    print(str(a.proj) + " " + str(a.mv));
    b = Shim(proj=[], mv=[], mode=0x1700);
    _setcur(b, [7.0, 6.0]);
    print(str(b.proj) + " " + str(b.mv));
}
