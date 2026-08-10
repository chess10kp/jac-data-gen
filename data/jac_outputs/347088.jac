""" return a copy of lst with duplicates of elements eliminated. For example, for lst = [a, a, a, a, b, c, c, a, a, d, e, e, e, e], the returned list is [a, b, c, d, e]. """
def remove_dups(lst: list[int | str]) -> list[int | str] {
    s = sorted(lst);
    [
        v
        for (i, v) in enumerate(s)
        if i == 0 or v != s[i - 1]
    ]
}