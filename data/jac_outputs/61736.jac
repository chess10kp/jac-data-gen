"""Return the range (min, max) of a dataset, excluding any NANs."""
def calcrange(data: Any, log: Any = False) -> object {
    (xmin, xmax) = (None, None);
    for x in data {
        if (not log or (x > 0.0)) {
            if ((xmin is None) or (x < xmin)) {
                xmin = x;
            }
            if ((xmax is None) or (x > xmax)) {
                xmax = x;
            }
        }
    }
    if ((xmin is None) and (xmax is None)) {
        if log {
            return (0.1, 1.0);
        } else {
            return (0.0, 1.0);
        }
    } else {
        return (xmin, xmax);
    }
}