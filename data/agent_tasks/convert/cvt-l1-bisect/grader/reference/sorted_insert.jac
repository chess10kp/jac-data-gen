"""Bisection algorithms: keep a list sorted without re-sorting after each insert.

Ported from CPython's bisect module (pure-Python implementation).
"""

"""Index where `x` should go in sorted `a` so that every e in a[:i] has e <= x.
Inserting at the returned index places `x` after any equal items already there."""
def bisect_right(
    a: list[any], x: any, lo: int = 0, hi: int | None = None, key: any = None
) -> int {
    if lo < 0 {
        raise ValueError("lo must be non-negative");
    }
    end: int = len(a) if hi is None else hi;
    while lo < end {
        mid = (lo + end) // 2;
        probe = a[mid] if key is None else key(a[mid]);
        if x < probe {
            end = mid;
        } else {
            lo = mid + 1;
        }
    }
    return lo;
}

"""Index where `x` should go in sorted `a` so that every e in a[:i] has e < x.
Inserting at the returned index places `x` before any equal items already there."""
def bisect_left(
    a: list[any], x: any, lo: int = 0, hi: int | None = None, key: any = None
) -> int {
    if lo < 0 {
        raise ValueError("lo must be non-negative");
    }
    end: int = len(a) if hi is None else hi;
    while lo < end {
        mid = (lo + end) // 2;
        probe = a[mid] if key is None else key(a[mid]);
        if probe < x {
            lo = mid + 1;
        } else {
            end = mid;
        }
    }
    return lo;
}

"""Insert `x` into sorted `a` in place, to the right of any equal items."""
def insort_right(
    a: list[any], x: any, lo: int = 0, hi: int | None = None, key: any = None
) {
    if key is None {
        a.insert(bisect_right(a, x, lo, hi), x);
    } else {
        a.insert(bisect_right(a, key(x), lo, hi, key=key), x);
    }
}

"""Insert `x` into sorted `a` in place, to the left of any equal items."""
def insort_left(
    a: list[any], x: any, lo: int = 0, hi: int | None = None, key: any = None
) {
    if key is None {
        a.insert(bisect_left(a, x, lo, hi), x);
    } else {
        a.insert(bisect_left(a, key(x), lo, hi, key=key), x);
    }
}
