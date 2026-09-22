"""[(1,2), (3,4)] -> [1, 2, 3, 4]"""
def merge_to_flat_list(_list: list[tuple[int, int]]) -> list[int] {
    return sum([list(item) for item in _list], []);
}