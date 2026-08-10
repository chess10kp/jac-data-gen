"""Return the list of cyclic permutations of the list lst"""
def _cyclic_permutations(lst: list[object]) -> list[list[object]] {
    if lst == [] {
        return [[]];
    }
    plst: list[list[object]] = [];
    for _ in range(len(lst)) {
        plst.append(lst);
        lst = lst[1:] + [lst[0]];
    }
    return plst;
}