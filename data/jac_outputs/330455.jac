"""Find out the idx of set where i is an element."""
def get_idx_set(i: object, sets: list[set[object]]) -> list[int] {
    idxs = [];
    for (j, set_j) in enumerate(sets) {
        if i in set_j {
            idxs.append(j);
        }
    }
    return idxs;
}