"""sepcifically for the rook, permutes the values needed around a position for noConflict tests"""
def knightList(x: int, y: int, int1: int, int2: int) -> list[tuple[int, int]] {
    [
        (x + int1, y + int2),
        (x - int1, y + int2),
        (x + int1, y - int2),
        (x - int1, y - int2),
        (x + int2, y + int1),
        (x - int2, y + int1),
        (x + int2, y - int1),
        (x - int2, y - int1)
    ]
}