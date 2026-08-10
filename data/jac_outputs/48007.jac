"""Returns a list of points which lie in a line defined by two endpoints"""
def get_lattice_points(tup1: Any, tup2: Any, check_diagonals: Any = True) -> object {
    (x1, y1) = (tup1[0], tup1[1]);
    (x2, y2) = (tup2[0], tup2[1]);
    if (y1 == y2) {
        if (x1 <= x2) {
            points = [(i, y1) for i in range(x1, (x2 + 1))];
            return points;
        } else {
            points = [(i, y1) for i in range(x2, (x1 + 1))];
            return points;
        }
    } elif (x1 == x2) {
        if (y1 <= y2) {
            points = [(x1, i) for i in range(y1, (y2 + 1))];
            return points;
        } else {
            points = [(x1, i) for i in range(y2, (y1 + 1))];
            return points;
        }
    } elif check_diagonals {
        slope = (y2 - y1) / (x2 - x1);
        y_int = y1 - (slope * x1);
        if (x1 <= x2) {
            points = [
                (i, int(((slope * i) + y_int)))
                for i in range(x1, (x2 + 1))
                if ((slope * i) + y_int).is_integer()
            ];
            return points;
        } else {
            points = [
                (i, int(((slope * i) + y_int)))
                for i in range(x2, (x1 + 1))
                if ((slope * i) + y_int).is_integer()
            ];
            return points;
        }
    }
}