"""Spin the last move program to the front."""
def spin(pgms: list[str], move: int) -> list[str] {
    return pgms[-move:] + pgms[:-move];
}