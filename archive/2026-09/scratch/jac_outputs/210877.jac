"""Calculate area of an arbitrary polygon using an algorithm from the web.

    Return the area of the polygon as a positive float.

    Arguments:
    points_list -- list of point tuples [(x0, y0), (x1, y1), (x2, y2), ...]
                   (Unclosed polygons will be closed automatically.
    precision -- Internal arithmetic precision (integer arithmetic).

    >>> polygon_area([(0, 0), (0, 1), (1, 1), (1, 2), (2, 2), (2, 0), (0, 0)])
    3.0

    Credits:
    Area of a General Polygon by David Chandler
    http://www.davidchandler.com/AreaOfAGeneralPolygon.pdf

    """
def polygon_area(points_list: list[tuple[float, float]], precision: int = 100) -> float {
    for i in range(len(points_list)) {
        points_list[i] = (
            int(points_list[i][0] * precision),
            int(points_list[i][1] * precision)
        ) as tuple[float, float];
    }
    if points_list[-1] != points_list[0] {
        points_list.append(points_list[0]);
    }
    area = 0;
    for i in range(len(points_list) - 1) {
        (x_i, y_i) = points_list[i] as tuple[int, int];
        (x_i_plus_1, y_i_plus_1) = points_list[i + 1] as tuple[int, int];
        area = area + x_i_plus_1 * y_i - y_i_plus_1 * x_i;
    }
    return float(abs(area / 2)) / (precision ** 2);
}