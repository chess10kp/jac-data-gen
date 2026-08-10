"""Return a set with the original order of elements preserved.

    credit: https://www.peterbe.com/plog/uniqifiers-benchmark
    """
def sort_preserve_order(sequence: list[object]) -> list[object] {
    seen = set();
    seen_add = seen.add;
    return [
        x
        for x in sequence
        if not (x in seen or seen_add(x))
    ];
}