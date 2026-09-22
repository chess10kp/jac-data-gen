"""
    Group a list into groups of adjacent elements. e.g.

    > group(list("AAABBCCDBBBBA"))
    [("A", 3), ("B", 2), ("C", 2), ("D", 1), ("B", 4), ("A", 1)]
    """
def group(l: list[str]) -> list[tuple[str, int]] {
    result = [];
    previous = None;
    count = 0;
    for elem in l {
        if previous is None {
            previous = elem;
            count = 1;
        } elif previous == elem {
            count += 1;
        } else {
            result.append((previous, count));
            previous = elem;
            count = 1;
        }
    }
    if previous is not None {
        result.append((previous, count));
    }
    return result;
}