"""Chunk the data into lists to k fold cv."""
def chunk_data(lst: list[object], n: int) -> list[list[object]] {
    increment = len(lst) / float(n);
    last = 0;
    index = 1;
    results = [];
    while last < len(lst) {
        idx = int(round(increment * index));
        results.append(lst[last:idx]);
        last = idx;
        index += 1;
    }
    return results;
}