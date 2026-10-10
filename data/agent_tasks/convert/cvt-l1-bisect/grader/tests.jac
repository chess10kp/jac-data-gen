# Hidden tests: CPython Lib/test/test_bisect.py (v3.12.7) ported to Jac.
import random;
import from sorted_insert { bisect_left, bisect_right, insort_left, insort_right }

# (data, elem, expected_right, expected_left) -- the upstream precomputed table.
glob CASES: list[tuple[list[float], float, int, int]] = [
    ([], 1, 0, 0),
    ([1], 0, 0, 0), ([1], 1, 1, 0), ([1], 2, 1, 1),
    ([1, 1], 0, 0, 0), ([1, 1], 1, 2, 0), ([1, 1], 2, 2, 2),
    ([1, 1, 1], 0, 0, 0), ([1, 1, 1], 1, 3, 0), ([1, 1, 1], 2, 3, 3),
    ([1, 1, 1, 1], 0, 0, 0), ([1, 1, 1, 1], 1, 4, 0), ([1, 1, 1, 1], 2, 4, 4),
    ([1, 2], 0, 0, 0), ([1, 2], 1, 1, 0), ([1, 2], 1.5, 1, 1), ([1, 2], 2, 2, 1), ([1, 2], 3, 2, 2),
    ([1, 1, 2, 2], 0, 0, 0), ([1, 1, 2, 2], 1, 2, 0), ([1, 1, 2, 2], 1.5, 2, 2),
    ([1, 1, 2, 2], 2, 4, 2), ([1, 1, 2, 2], 3, 4, 4),
    ([1, 2, 3], 0, 0, 0), ([1, 2, 3], 1, 1, 0), ([1, 2, 3], 1.5, 1, 1), ([1, 2, 3], 2, 2, 1),
    ([1, 2, 3], 2.5, 2, 2), ([1, 2, 3], 3, 3, 2), ([1, 2, 3], 4, 3, 3),
    ([1, 2, 2, 3, 3, 3, 4, 4, 4, 4], 0, 0, 0), ([1, 2, 2, 3, 3, 3, 4, 4, 4, 4], 1, 1, 0),
    ([1, 2, 2, 3, 3, 3, 4, 4, 4, 4], 1.5, 1, 1), ([1, 2, 2, 3, 3, 3, 4, 4, 4, 4], 2, 3, 1),
    ([1, 2, 2, 3, 3, 3, 4, 4, 4, 4], 2.5, 3, 3), ([1, 2, 2, 3, 3, 3, 4, 4, 4, 4], 3, 6, 3),
    ([1, 2, 2, 3, 3, 3, 4, 4, 4, 4], 3.5, 6, 6), ([1, 2, 2, 3, 3, 3, 4, 4, 4, 4], 4, 10, 6),
    ([1, 2, 2, 3, 3, 3, 4, 4, 4, 4], 5, 10, 10)
];

test "precomputed" {
    for (data, elem, right, left) in CASES {
        assert bisect_right(data, elem) == right;
        assert bisect_left(data, elem) == left;
    }
}

test "optional slicing" {
    for (data, elem, right, left) in CASES {
        for lo0 in range(4) {
            lo = min(len(data), lo0);
            for hi0 in range(3, 8) {
                hi = min(len(data), hi0);
                ip = bisect_left(data, elem, lo, hi);
                assert lo <= ip and ip <= hi;
                if ip < hi { assert elem <= data[ip]; }
                if ip > lo { assert data[ip - 1] < elem; }
                assert ip == max(lo, min(hi, left));
                ip = bisect_right(data, elem, lo, hi);
                assert lo <= ip and ip <= hi;
                if ip < hi { assert elem < data[ip]; }
                if ip > lo { assert data[ip - 1] <= elem; }
                assert ip == max(lo, min(hi, right));
            }
        }
    }
}

test "negative lo raises" {
    hits = 0;
    try { bisect_left([1, 2, 3], 5, -1, 3); } except ValueError { hits += 1; }
    try { bisect_right([1, 2, 3], 5, -1, 3); } except ValueError { hits += 1; }
    try { insort_left([1, 2, 3], 5, -1, 3); } except ValueError { hits += 1; }
    try { insort_right([1, 2, 3], 5, -1, 3); } except ValueError { hits += 1; }
    assert hits == 4;
}

test "random invariants" {
    rng = random.Random(1234);
    n = 25;
    for i in range(n) {
        data = sorted([rng.randrange(0, n, 2) for j in range(i)]);
        elem = rng.randrange(-1, n + 1);
        ip = bisect_left(data, elem);
        if ip < len(data) { assert elem <= data[ip]; }
        if ip > 0 { assert data[ip - 1] < elem; }
        ip = bisect_right(data, elem);
        if ip < len(data) { assert elem < data[ip]; }
        if ip > 0 { assert data[ip - 1] <= elem; }
    }
}

test "keyword args" {
    data = [10, 20, 30, 40, 50];
    assert bisect_left(a=data, x=25, lo=1, hi=3) == 2;
    assert bisect_right(a=data, x=25, lo=1, hi=3) == 2;
    insort_left(a=data, x=25, lo=1, hi=3);
    insort_right(a=data, x=25, lo=1, hi=3);
    insort_right(a=data, x=25, lo=1, hi=3);
    assert data == [10, 20, 25, 25, 25, 30, 40, 50];
}

test "lookups with key function" {
    arr = sorted([2, -4, 6, 8, -10], key=abs);
    pre = [abs(v) for v in arr];
    for x in pre {
        assert bisect_left(arr, x, key=abs) == bisect_left(pre, x);
        assert bisect_right(arr, x, key=abs) == bisect_right(pre, x);
    }
    chars = sorted(list("aBcDeEfgHhiIiij"), key=str.casefold);
    folded = [c.casefold() for c in chars];
    for x in folded {
        assert bisect_left(chars, x, key=str.casefold) == bisect_left(folded, x);
        assert bisect_right(chars, x, key=str.casefold) == bisect_right(folded, x);
    }
}

test "insort with key keeps order and stability" {
    rng = random.Random(99);
    data = list(range(-10, 11)) + list(range(-20, 20, 2));
    rng.shuffle(data);
    target: list[int] = [];
    for x in data {
        insort_left(target, x, key=abs);
        assert target == sorted(target, key=abs);
    }
    target2: list[int] = [];
    for x in data {
        insort_right(target2, x, key=abs);
        assert target2 == sorted(target2, key=abs);
    }
    # left vs right placement among equal keys
    l = [1, -1];
    insort_left(l, 1, key=abs);
    assert l[0] == 1 and len(l) == 3;
    r = [-1, 2];
    insort_right(r, 1, key=abs);
    assert r == [-1, 1, 2];
    r2 = [-1, 2];
    insort_left(r2, 1, key=abs);
    assert r2 == [1, -1, 2];
}

test "insort placement among equal items without key" {
    a: list[float] = [1, 2];
    insort_left(a, 1.0);
    assert isinstance(a[0], float) and not isinstance(a[1], float);
    b: list[float] = [1, 2];
    insort_right(b, 1.0);
    assert not isinstance(b[0], float) and isinstance(b[1], float);
}

test "insort matches builtin sort" {
    rng = random.Random(7);
    got: list[float] = [];
    for i in range(500) {
        digit = rng.choice("0123456789");
        v = float(digit) + rng.random();
        if digit in "02468" {
            insort_left(got, v);
        } else {
            insort_right(got, v);
        }
    }
    assert got == sorted(got);
    assert len(got) == 500;
}

test "grades doc example" {
    breakpoints = [60, 70, 80, 90];
    grades = "FDCBA";
    result = [grades[bisect_right(breakpoints, s)] for s in [33, 99, 77, 70, 89, 90, 100]];
    assert result == ["F", "A", "C", "C", "B", "A", "A"];
}

test "colors doc example" {
    data = sorted([("red", 5), ("blue", 1), ("yellow", 8), ("black", 0)], key=lambda (r: tuple[str, int]) -> int { return r[1]; });
    keys = [r[1] for r in data];
    assert data[bisect_left(keys, 0)] == ("black", 0);
    assert data[bisect_left(keys, 1)] == ("blue", 1);
    assert data[bisect_left(keys, 5)] == ("red", 5);
    assert data[bisect_left(keys, 8)] == ("yellow", 8);
}
