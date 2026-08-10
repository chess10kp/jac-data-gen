"""Extract summer from month values."""
def get_season(x: int) -> tuple[int, int, int, int] {
    summer = 0;
    fall = 0;
    winter = 0;
    spring = 0;
    if x in (5, 6, 7) {
        summer = 1;
    }
    if x in (8, 9, 10) {
        fall = 1;
    }
    if x in (11, 0, 1) {
        winter = 1;
    }
    if x in (2, 3, 4) {
        spring = 1;
    }
    return (summer, fall, winter, spring);
}