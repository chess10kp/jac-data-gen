"""Shift with height s origin = 0,0"""
def shiftCoordsForHeight(s: int | float) -> tuple[tuple[tuple[float, float], ...]] {
    (
        (
            (s / 2, s),
            (0, (s * 4) / 9),
            ((s * 4) / 15, (s * 4) / 9),
            ((s * 4) / 15, 0),
            ((s * 11) / 15, 0),
            ((s * 11) / 15, (s * 4) / 9),
            (s, (s * 4) / 9)
        ),
    )
}