"""
    Compute the mean value of the entries in {iterable}
    """
def mean(iterable: Any) -> object {
    i = iter(iterable);
    count = 1;
    total = next(i);
    for item in i {
        count += 1;
        total += item;
    }
    return ((total * 1) / count);
}