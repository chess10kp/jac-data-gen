"""Check of Collision bird to wall."""
def isCollision(x: int, y: int, wallBuf: list[list[int]]) -> bool {
    for wall in wallBuf {
        if x in range(wall[0], wall[0] + 40) {
            if not y in range(wall[1] - 100, wall[1]) {
                return True;
            }
        }
    }
    return False;
}