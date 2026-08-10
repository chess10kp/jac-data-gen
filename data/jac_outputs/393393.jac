glob LEFT = 1;
glob RIGHT = 2;
glob LOWER = 4;
glob UPPER = 8;

"""Clips a line to a rectangular area.

This implements the Cohen-Sutherland line clipping algorithm.  left,
top, right and bottom denote the clipping area, into which the line
defined by x1, y1 (start point) and x2, y2 (end point) will be
clipped.

If the line does not intersect with the rectangular clipping area,
four None values will be returned as tuple. Otherwise a tuple of the
clipped line points will be returned in the form (cx1, cy1, cx2, cy2).
"""
def cohensutherland(
    left: float, top: float, right: float, bottom: float,
    x1: float, y1: float, x2: float, y2: float
) -> tuple[float | None, float | None, float | None, float | None] {
    def _getclip(xa: float, ya: float) -> int {
        p = 0;
        if xa < left {
            p = LEFT;
        } elif xa > right {
            p = RIGHT;
        }
        if ya < top {
            p |= LOWER;
        } elif ya > bottom {
            p |= UPPER;
        }
        return p;
    }
    k1 = _getclip(x1, y1);
    k2 = _getclip(x2, y2);
    while (k1 | k2) != 0 {
        if (k1 & k2) != 0 {
            return (None, None, None, None);
        }
        opt = k1 or k2;
        if opt & UPPER {
            x = x1 + ((x2 - x1) * (1.0 * (bottom - y1))) / (y2 - y1);
            y = bottom;
        } elif opt & LOWER {
            x = x1 + ((x2 - x1) * (1.0 * (top - y1))) / (y2 - y1);
            y = top;
        } elif opt & RIGHT {
            y = y1 + ((y2 - y1) * (1.0 * (right - x1))) / (x2 - x1);
            x = right;
        } elif opt & LEFT {
            y = y1 + ((y2 - y1) * (1.0 * (left - x1))) / (x2 - x1);
            x = left;
        } else {
            raise RuntimeError("invalid clipping state");
        }
        if opt == k1 {
            (x1, y1) = (x, y);
            k1 = _getclip(x1, y1);
        } else {
            (x2, y2) = (x, y);
            k2 = _getclip(x2, y2);
        }
    }
    return (x1, y1, x2, y2);
}