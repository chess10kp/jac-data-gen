"""Convert from tuple to packed list."""
def to_list(tup: tuple[object, ...]) -> list[list[object]] {
    n_tup = len(tup);
    if n_tup == 0 {
        return [];
    }
    if not isinstance(tup[0], list) {
        if n_tup == 1 {
            return [list(tup)];
        }
        if n_tup % 2 != 0 {
            raise ValueError(
                'Don\'t know how to handle uneven number of args '
                'without a list. Please wrap your args in a list.'
            );
        }
        return [list(el) for el in zip(tup[:n_tup // 2], tup[n_tup // 2:])];
    }
    if n_tup == 1 {
        return [[x] for x in tup[0]];
    }
    n_mods = len(tup[0]);
    lists_packed = [[] for _ in range(n_mods)];
    for i in range(n_mods) {
        for j in range(n_tup) {
            lists_packed[i].append(tup[j][i]);
        }
    }
    return lists_packed;
}