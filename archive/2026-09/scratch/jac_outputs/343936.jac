""" return a triple tuple containing HSL values given
        a triple tuple of rgb data ( blue, green, red ) format
    """
def RGBtoHSL(rgb: Any) -> object {
    Rp = rgb[2] / 255;
    Gp = rgb[1] / 255;
    Bp = rgb[0] / 255;
    Cmax = max(Rp, Gp, Bp);
    Cmin = min(Rp, Gp, Bp);
    Delta = Cmax - Cmin;
    if (Delta == 0) {
        Hue = 0;
    } elif (Cmax == Rp) {
        Hue = 60 * (((Gp - Bp) / Delta) % 6);
    } elif (Cmax == Gp) {
        Hue = 60 * (((Bp - Rp) / Delta) + 2);
    } else {
        Hue = 60 * (((Rp - Gp) / Delta) + 4);
    }
    Lit = (Cmax + Cmin) / 2;
    if (Delta == 0) {
        Sat = 0;
    } else {
        Sat = Delta / (1 - abs(((2 * Lit) - 1)));
    }
    return (Hue, Sat, Lit);
}