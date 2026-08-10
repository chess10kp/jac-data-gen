"""
hsv: [h, s, v]
    h in [0, 360]
    s in [0, 1]
    v in [0, 1]
return [r, g, b]
    r, g, b in [0, 1]
"""
def hsv2rgb(hsv: list[float]) -> list[float] {
    h = hsv[0];
    s = hsv[1];
    v = hsv[2];
    hd = h / 60;
    r = v;
    g = v;
    b = v;
    if s > 0 {
        hdi = max(0, min(5, int(hd)));
        f = hd - hdi;
        if hdi == 0 {
            g *= 1 - s * (1 - f);
            b *= 1 - s;
        } elif hdi == 1 {
            r *= 1 - s * f;
            b *= 1 - s;
        } elif hdi == 2 {
            r *= 1 - s;
            b *= 1 - s * (1 - f);
        } elif hdi == 3 {
            r *= 1 - s;
            g *= 1 - s * f;
        } elif hdi == 4 {
            r *= 1 - s * (1 - f);
            g *= 1 - s;
        } elif hdi == 5 {
            g *= 1 - s;
            b *= 1 - s * f;
        }
    }
    return [r, g, b];
}