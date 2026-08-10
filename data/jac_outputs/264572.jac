"""
Implements the minimum set cover algorithm to find non-overlapping sets
out of the 80 ribosomal sampled regions
"""
def get_minimum_set_cover(nodelist: list[int], listofsubsets: list[set[int]]) -> list[set[int]] | None {
    indices = set(range(len(nodelist)));
    elems = set(e for s in listofsubsets for e in s);
    if elems != indices {
        return None;
    }
    covered = set();
    cover: list[set[int]] = [];
    while covered != elems {
        subset = max(listofsubsets, key=lambda (s: set[int]) { len(s - covered); });
        cover.append(subset);
        covered |= subset;
    }
    return cover;
}