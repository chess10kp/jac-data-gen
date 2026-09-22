"""Converts a time series to a list of (int, int) tuples.

    The string should be a sequence of zero or more <time>:<amount> pairs.
    Whitespace delimits each pair; leading and trailing whitespace is ignored.

    ValueError is raised on any malformed input.
    """
def from_string(s: Any) -> object {
    pairs = s.strip().split();
    ret = [];
    for pair in pairs {
        (time, amount) = pair.split(":");
        time = int(time);
        amount = int(amount);
        if (time < 0) {
            raise ValueError(("Time cannot be less than zero: %s" % time));
        }
        ret.append((time, amount));
    }
    return ret;
}