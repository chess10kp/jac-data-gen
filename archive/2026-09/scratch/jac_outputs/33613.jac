"""
    Tells if streets `st1`, `st2` are connected.

    Each tuple means:

    * 0 or 1 mean first or last extremity or the first street
    * 0 or 1 mean first or last extremity or the second street

    ``((0, 1),)`` means the first point of the first street is connected
    to the second extremity of the second street.
"""
def connect_streets(st1: list[tuple[float, float]], st2: list[tuple[float, float]]) -> tuple[tuple[int, int], ...] | None {
    (a1, b1) = (st1[0], st1[-1]);
    (a2, b2) = (st2[0], st2[-1]);
    connect: list[tuple[int, int]] = [];
    if a1 == a2 {
        connect.append((0, 0));
    }
    if a1 == b2 {
        connect.append((0, 1));
    }
    if b1 == a2 {
        connect.append((1, 0));
    }
    if b1 == b2 {
        connect.append((1, 1));
    }
    return tuple(connect) if connect else None;
}