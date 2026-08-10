"""
Takes a tuple of coordinates (x,y) and returns corresponding
keypad number
"""
def keypad(coords: tuple[int, int]) -> int | str {
    x = coords[0];
    y = coords[1];
    key = [
        ["N", "N", 1, "N", "N"],
        ["N", 2, 3, 4, "N"],
        [5, 6, 7, 8, 9],
        ["N", "A", "B", "C", "N"],
        ["N", "N", "D", "N", "N"]
    ];
    return key[x][y];
}