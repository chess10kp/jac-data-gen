"""Return the day count when a growing plant reaches the desired height."""
def growing_plant(upSpeed: int, downSpeed: int, desiredHeight: int) -> int {
    height = 0;
    days = 0;
    while height <= desiredHeight {
        height += upSpeed;
        days += 1;
        if height >= desiredHeight {
            return days;
        }
        height -= downSpeed;
    }
    return days;
}