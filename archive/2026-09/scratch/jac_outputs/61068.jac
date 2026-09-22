"""Returns a list of chunks containing at most chunksize elements of data."""
def chunked(data: list[object], chunksize: int | float) -> list[list[object]] {
    if chunksize < 1 {
        raise ValueError("Chunksize must be at least 1!");
    }
    if int(chunksize) != chunksize {
        raise ValueError("Chunksize needs to be an integer");
    }
    res = [];
    cur = [];
    for e in data {
        cur.append(e);
        if len(cur) >= chunksize {
            res.append(cur);
            cur = [];
        }
    }
    if cur {
        res.append(cur);
    }
    return res;
}