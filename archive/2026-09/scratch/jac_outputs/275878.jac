"""
    Count the number of consecutive repeats in a list.

    Essentially, a way of doing `uniq -c`
    """
def condense_repeats(ll: list[object], use_is: bool = True) -> list[tuple[object, int]] {
    count = 0;
    old = None;
    vals = [];
    for e in ll {
        if use_is and e is old or not use_is and e == old {
            count += 1;
        } else {
            if old is not None {
                vals.append((old, count));
            }
            count = 1;
            old = e;
        }
    }
    vals.append((old, count));
    return vals;
}