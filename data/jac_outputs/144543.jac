"""Extract consecutive ranges and singles from a monotone index list."""
def extract_ranges(index_list: list[int], range_size_limit: int = 32) -> tuple[list[list[int]], list[int]] {
    if not index_list {
        return ([], []);
    }
    first = index_list[0];
    last = first;
    ranges: list[list[int]] = [];
    singles: list[int] = [];
    for i in index_list[1:] {
        if i == last + 1 and last - first <= range_size_limit {
            last = i;
        } else {
            if last > first {
                ranges.append([first, last]);
            } else {
                singles.append(first);
            }
            first = i;
            last = i;
        }
    }
    if last > first {
        ranges.append([first, last]);
    } else {
        singles.append(first);
    }
    return (ranges, singles);
}