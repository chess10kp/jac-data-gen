"""
Gets the floor value of the positive square root of a number
"""
def sqrt(x: int) -> int {
    assert x >= 0;
    z = 0;
    if x > 3 {
        z = x;
        y = (x // 2) + 1;
        while y < z {
            z = y;
            y = ((x // y) + y) // 2;
        }
    } elif x != 0 {
        z = 1;
    }
    z
}