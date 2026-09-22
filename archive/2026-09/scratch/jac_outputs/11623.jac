"""
Split array into chunks of chunksize (last chunk may be smaller).
"""
def chunk(mylist: list[object], chunksize: int) -> list[list[object]] {
    n = len(mylist);
    bounds = list(range(0, n, chunksize)) + [n];
    return [mylist[i:j] for (i, j) in zip(bounds[:-1], bounds[1:])];
}