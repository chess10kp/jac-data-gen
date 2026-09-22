"""Gets the data specified by the keys in the data_list from the data_cache."""
def get_data(
    data_list: str | list[str],
    data_cache: dict[str, tuple[list[int], list[int]]]
) -> tuple[list[int], list[int]] | tuple[list[list[int]], list[list[int]]] {
    if not isinstance(data_list, list) {
        data_list = [data_list];
    }
    tmp = [data_cache[d] for d in data_list];
    if len(tmp) == 1 {
        return tmp[0];
    }
    return ([t[0] for t in tmp], [t[1] for t in tmp]);
}