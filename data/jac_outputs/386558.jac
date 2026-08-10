"""Expands the Haskell-like range given as a parameter
    into Python's `range` object. The range must be finite.

    Args:
        val (str): a range to expand.

    Returns:
        range: resulting range.

    Raises:
        ValueError: if given an invalid Haskell-like range.

    >>> expand_range("[1..10]")
    range(1, 11)

    >>> expand_range("[1,3..10]")
    range(1, 11, 2)

    >>> expand_range("[5,4..1]")
    range(5, 0, -1)
    """
def expand_range(val: Any) -> object {
    if (not val.startswith("[") or not val.endswith("]")) {
        raise ValueError("Invalid bracket placement");
    }
    val = val[1:-1];
    spl = val.split("..");
    if ((len(spl) != 2) or not all(spl)) {
        raise ValueError("Invalid range");
    }
    end = int(spl[1]);
    if ("," in spl[0]) {
        (begin, bstep) = map(int, spl[0].split(","));
        step = bstep - begin;
    } else {
        begin = int(spl[0]);
        step = 1;
    }
    if (step == 0) {
        raise ValueError("Zero step is not allowed");
    }
    if (step > 0) {
        end += 1;
    } else {
        end -= 1;
    }
    return range(begin, end, step);
}