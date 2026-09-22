"""
    sbox is (lat1, lat2, long1, long2),
    dbox is (x1, x2, y1, y2),
    v is (lat, long).
    result is (x, y)
    """
def map_box(sbox: Any, dbox: Any, v: Any) -> object {
    xscale = abs((dbox[1] - dbox[0])) / abs((sbox[3] - sbox[2]));
    yscale = abs((dbox[3] - dbox[2])) / abs((sbox[1] - sbox[0]));
    x = ((v[1] - sbox[2]) + dbox[0]) * xscale;
    y = ((v[0] - sbox[0]) + dbox[2]) * yscale;
    return (x, y);
}