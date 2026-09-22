"""Calculates the appropriate bitmasks for a color stored in ARGB format."""
def calc_bitmasks_ARGB_color(bdR: int, bdG: int, bdB: int, bdA: int) -> list[int] {
    red_mask = 0;
    green_mask = 0;
    blue_mask = 0;
    alpha_mask = 0;
    if bdA > 0 {
        for _ in range(bdA) {
            alpha_mask = (alpha_mask << 1) + 1;
        }
        alpha_mask = alpha_mask << (bdR + bdG + bdB);
    }
    for _ in range(bdR) {
        red_mask = (red_mask << 1) + 1;
    }
    red_mask = red_mask << (bdG + bdB);
    for _ in range(bdG) {
        green_mask = (green_mask << 1) + 1;
    }
    green_mask = green_mask << bdB;
    for _ in range(bdB) {
        blue_mask = (blue_mask << 1) + 1;
    }
    return [red_mask, green_mask, blue_mask, alpha_mask];
}