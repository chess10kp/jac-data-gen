""" [(1,2), (3,4)] -> [1, 2, 3, 4]"""
def make_flat(list_of_lists: list[list[int] | tuple[int, int]]) -> list[int] {
    return sum([list(item) for item in list_of_lists], []);
}