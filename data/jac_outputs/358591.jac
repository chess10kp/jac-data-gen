"""Returns nearest two indices which bracket a specified value in a vector.

Given an input list or numpy 1-D array, which is asumed to be monotonically
increasing or decreasing, find the indices of the two points with values closest
to parameter 'value'.
"""
def NearestIndex(
    vector: list[float], value: float, noPrint: bool = False, debug: bool = False
) -> tuple[int, int] | tuple[None, None] | None {
    npts = len(vector);
    if value < min(vector) or value > max(vector) {
        if noPrint {
            return (None, None);
        }
        msg = "   value {0} lies outside range of input vector ({1} to {2})!".format(
            value, min(vector), max(vector)
        );
        print(msg);
        return None;
    }
    diff1 = vector[1] - vector[0];
    sign = 1 if diff1 > 0 else -1;
    i1 = i2 = 0;
    diff = sign * (value - vector[0]);
    if debug {
        print(diff);
    }
    for i in range(1, npts) {
        newdiff = sign * (value - vector[i]);
        if debug {
            print(i, newdiff);
        }
        if newdiff > 0 and newdiff <= diff {
            diff = newdiff;
            i1 = i;
        } else {
            i2 = i;
            break;
        }
    }
    if noPrint is False {
        print(
            "   input_vector[{0},{1}] = {2}, {3}".format(i1, i2, vector[i1], vector[i2])
        );
    }
    return (i1, i2);
}